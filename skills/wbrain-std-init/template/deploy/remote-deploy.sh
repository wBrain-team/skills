#!/bin/bash
# Roda NA EC2, como root (enviado por deploy.sh via SSM). Idempotente.
# Recebe a configuração como variáveis DEPLOY_CFG_* no cabeçalho do script (ver remote_env_header em deploy.sh):
#   atualiza o código (git + deploy key), regrava o env_file a partir do Secrets Manager,
#   sobe a stack com docker compose e valida o health_url. Rollback automático só com DEPLOY_CFG_AUTO_ROLLBACK=true.
set -euo pipefail
export HOME=/root

for var in DEPLOY_CFG_NAME DEPLOY_CFG_REPO DEPLOY_CFG_BRANCH DEPLOY_CFG_APP_DIR DEPLOY_CFG_COMPOSE_FILES DEPLOY_CFG_ENV_FILE DEPLOY_CFG_DATA_DIRS \
  DEPLOY_CFG_PROXY_SERVICE DEPLOY_CFG_HEALTH_URL DEPLOY_CFG_HEALTH_TIMEOUT DEPLOY_CFG_SECRET DEPLOY_CFG_REGION; do
  [ -n "${!var:-}" ] || { echo "Variável ausente: $var (rode pelo deploy.sh)." >&2; exit 64; }
done
# A saída do SSM é truncada: o log completo fica na instância (/var/log/<name>-deploy.log, lido via shell).
exec > >(tee -a "/var/log/${DEPLOY_CFG_NAME}-deploy.log") 2>&1
# Opcionais: ref implantada em vez da ponta da branch (deploy --ref) e rollback automático (deploy.auto_rollback).
REF=${DEPLOY_CFG_REF:-}
AUTO_ROLLBACK=${DEPLOY_CFG_AUTO_ROLLBACK:-false}

DEPLOY_KEY=/root/.ssh/${DEPLOY_CFG_NAME}_deploy
LOCK_FILE=/var/lock/${DEPLOY_CFG_NAME}-deploy.lock
PREVIOUS_SHA=nenhum

COMPOSE=(docker compose)
for compose_file in $DEPLOY_CFG_COMPOSE_FILES; do
  COMPOSE+=(-f "$compose_file")
done
# HTTPS público é opcional (https.enabled no config.yaml): só então o compose do proxy e do renovador entram na stack.
HTTPS_ENABLED=${DEPLOY_CFG_HTTPS_ENABLED:-false}
HTTPS_CERT_DIR=/ext-vol/letsencrypt
HTTPS_WEBROOT_DIR=/ext-vol/acme-webroot
# Envs dos containers do HTTPS num arquivo (env_file do compose), não no ambiente do deploy: assim um
# `docker compose` manual na instância (./deploy.sh shell) também funciona. Ignorado pelo git (deploy/https/.gitignore).
HTTPS_ENV_FILE=deploy/https/.https.env
if [ "$HTTPS_ENABLED" = true ]; then
  COMPOSE+=(-f deploy/https/docker-compose.https.yml)
fi

# known_hosts vem do setup, com a host key do provedor já verificada: sem TOFU na instância.
export GIT_SSH_COMMAND="ssh -i $DEPLOY_KEY -o IdentitiesOnly=yes -o UserKnownHostsFile=/root/.ssh/known_hosts -o StrictHostKeyChecking=yes"

# Logs só dos serviços parados ou unhealthy: os saudáveis não explicam a falha e o log da instância
# (e do CloudWatch) não deve acumular saída de containers à toa. Sem nenhum assim (só o health_url falhou),
# mostra todos.
show_failed_logs() {
  local failed
  failed=$("${COMPOSE[@]}" ps -a --format '{{.Service}} {{.State}} {{.Health}}' 2>/dev/null \
    | awk '$2 != "running" || $3 == "unhealthy" { print $1 }' | sort -u || true)
  "${COMPOSE[@]}" ps -a >&2 || true
  # shellcheck disable=SC2086 # lista de serviços separada por linha: o split é intencional
  "${COMPOSE[@]}" logs --tail=50 $failed >&2 || true
}

# shellcheck disable=SC2329 # chamada pelo trap ERR abaixo
on_error() {
  echo "❌ Deploy falhou. SHA anterior: $PREVIOUS_SHA." >&2
  if [ -d "$DEPLOY_CFG_APP_DIR" ]; then
    (cd "$DEPLOY_CFG_APP_DIR" && show_failed_logs) || true
  fi
}
trap on_error ERR

# Mesmo lock do host-setup.sh: setup (que pode reiniciar o Docker) e deploy nunca rodam juntos.
exec 9>"$LOCK_FILE"
flock -n 9 || { echo "Outro deploy ou setup já está em andamento." >&2; exit 1; }

# Dados persistentes e o código vivem no volume EBS montado aqui. Sem ele, os containers gravariam no disco
# raiz e os dados sumiriam quando o volume voltasse. Fixo: é o ponto de montagem definido em user-data.sh.tftpl.
DATA_MOUNT=/ext-vol
MIN_FREE_GB=5
mountpoint -q "$DATA_MOUNT" || { echo "$DATA_MOUNT não está montado: abortando para não gravar dados no disco raiz." >&2; exit 1; }
# Imagens e cache de build ficam no data-root do Docker (disco raiz), não no /ext-vol: os dois precisam de folga.
require_free_space() {
  local free_gb
  free_gb=$(df --output=avail -BG "$1" | tail -1 | tr -dc '0-9')
  [ "$free_gb" -ge "$MIN_FREE_GB" ] || { echo "Espaço livre em $1: ${free_gb}G (mínimo ${MIN_FREE_GB}G para o build)." >&2; exit 1; }
}
require_free_space "$DATA_MOUNT"
require_free_space "$(docker info --format '{{.DockerRootDir}}')"

{ [ -f "$DEPLOY_KEY" ] && [ -f /root/.ssh/known_hosts ]; } || { echo "Deploy key ou known_hosts ausente: rode ./deploy.sh setup antes." >&2; exit 1; }
if ! git ls-remote --exit-code "$DEPLOY_CFG_REPO" HEAD >/dev/null 2>&1; then
  echo "Sem acesso a $DEPLOY_CFG_REPO. Cadastre esta chave como Deploy Key (somente leitura) no repositório:" >&2
  cat "$DEPLOY_KEY.pub" >&2
  exit 1
fi

# Lê o secret antes de mexer no código: secret vazio aborta sem alterar nada.
env_content=$(aws secretsmanager get-secret-value --region "$DEPLOY_CFG_REGION" --secret-id "$DEPLOY_CFG_SECRET" \
  --query SecretString --output text)
{ [ -n "$env_content" ] && [ "$env_content" != "None" ]; } || {
  echo "Secret $DEPLOY_CFG_SECRET está vazio: preencha-o com o conteúdo do $DEPLOY_CFG_ENV_FILE." >&2
  exit 1
}

# shellcheck disable=SC2086 # DEPLOY_CFG_DATA_DIRS é uma lista de caminhos separada por espaço: o split é intencional
mkdir -p "$(dirname "$DEPLOY_CFG_APP_DIR")" $DEPLOY_CFG_DATA_DIRS
if [ "$HTTPS_ENABLED" = true ]; then
  mkdir -p "$HTTPS_CERT_DIR" "$HTTPS_WEBROOT_DIR"
fi
if [ ! -d "$DEPLOY_CFG_APP_DIR/.git" ]; then
  # Diretório sem .git é resto de um clone que falhou: não é apagado automaticamente.
  [ ! -e "$DEPLOY_CFG_APP_DIR" ] || { echo "$DEPLOY_CFG_APP_DIR existe sem .git (clone anterior incompleto?): remova-o à mão." >&2; exit 1; }
  git clone --branch "$DEPLOY_CFG_BRANCH" "$DEPLOY_CFG_REPO" "$DEPLOY_CFG_APP_DIR"
fi
cd "$DEPLOY_CFG_APP_DIR"
PREVIOUS_SHA=$(git rev-parse HEAD)
git fetch --prune origin "+refs/heads/$DEPLOY_CFG_BRANCH:refs/remotes/origin/$DEPLOY_CFG_BRANCH"
if [ -n "$REF" ]; then
  # --force: tag movida no remoto atualiza a local (sem ele o fetch recusa e o deploy aborta).
  git fetch -q --force --tags origin
  # Ordem: branch remota, tag, SHA. Nunca a branch local: o checkout -B a deixa no SHA do deploy anterior,
  # e `--ref main` reimplantaria o código antigo.
  if git ls-remote --exit-code --heads origin "$REF" >/dev/null 2>&1; then
    git fetch -q origin "+refs/heads/$REF:refs/remotes/origin/$REF"
    TARGET_SHA=$(git rev-parse "refs/remotes/origin/$REF")
  elif TARGET_SHA=$(git rev-parse --verify -q "refs/tags/$REF^{commit}"); then
    :
  elif [[ "$REF" =~ ^[0-9a-fA-F]{7,40}$ ]] && TARGET_SHA=$(git rev-parse --verify -q "$REF^{commit}"); then
    :
  else
    echo "Ref não encontrada no repositório (branch remota, tag ou SHA): $REF" >&2
    exit 1
  fi
else
  TARGET_SHA=$(git rev-parse "origin/$DEPLOY_CFG_BRANCH")
fi

# Árvore da instância é só cópia do repositório: alterações locais e arquivos não rastreados são descartados.
# Sem -x, o git clean preserva os ignorados (ex.: o env_file, gerado a seguir).
checkout_sha() {
  git checkout -q -f -B "$DEPLOY_CFG_BRANCH" "$1"
  git clean -qfd
}
checkout_sha "$TARGET_SHA"
echo "Código: $PREVIOUS_SHA → $(git rev-parse HEAD) (${REF:-branch $DEPLOY_CFG_BRANCH})"

# Os envs do ambiente vivem só no secret; o env_file é regravado a cada deploy.
# umask só no subshell: fora dele, o checkout do rollback criaria o código com 0600 (ilegível nos bind mounts).
(umask 077; printf '%s\n' "$env_content" > "$DEPLOY_CFG_ENV_FILE.new")
mv "$DEPLOY_CFG_ENV_FILE.new" "$DEPLOY_CFG_ENV_FILE"

write_https_env() {
  [ "$HTTPS_ENABLED" = true ] || return 0
  printf 'HTTPS_DOMAINS=%s\nHTTPS_EMAIL=%s\nHTTPS_STAGING=%s\nHTTPS_RENEW_DAY=%s\n' \
    "$DEPLOY_CFG_HTTPS_DOMAINS" "$DEPLOY_CFG_HTTPS_EMAIL" "${DEPLOY_CFG_HTTPS_STAGING:-false}" "${DEPLOY_CFG_HTTPS_RENEW_DAY:-1}" \
    > "$HTTPS_ENV_FILE"
}
write_https_env

# Confere o contrato do projeto (deploy/CONTRACT.md) antes de qualquer `up`.
preflight() {
  local file version missing
  for file in $DEPLOY_CFG_COMPOSE_FILES; do
    [ -f "$file" ] || { echo "Preflight: arquivo do compose ausente: $file." >&2; return 1; }
  done
  version=$(docker compose version --short)
  [ "$(printf '%s\n%s\n' 2.24.0 "$version" | sort -V | head -1)" = "2.24.0" ] || {
    echo "Preflight: Docker Compose $version é antigo; exige >= 2.24.0." >&2
    return 1
  }
  "${COMPOSE[@]}" config -q || { echo "Preflight: docker compose config inválido." >&2; return 1; }
  if [ -f "$DEPLOY_CFG_ENV_FILE.example" ]; then
    missing=$(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$DEPLOY_CFG_ENV_FILE.example" | cut -d= -f1 \
      | while read -r key; do grep -q "^$key=" "$DEPLOY_CFG_ENV_FILE" || echo "$key"; done || true)
    [ -z "$missing" ] || echo "AVISO: chaves de $DEPLOY_CFG_ENV_FILE.example ausentes no secret: ${missing//$'\n'/ }" >&2
  fi
}
preflight

# Até health_timeout segundos (arredondado para cima, mínimo uma tentativa); cada curl tem limite próprio,
# senão um backend que aceita a conexão e não responde prenderia o deploy até o timeout do SSM.
wait_healthy() {
  local attempts=$(((DEPLOY_CFG_HEALTH_TIMEOUT + 4) / 5)) _
  [ "$attempts" -ge 1 ] || attempts=1
  for _ in $(seq 1 "$attempts"); do
    curl -fsS --max-time 5 "$DEPLOY_CFG_HEALTH_URL" >/dev/null 2>&1 && return 0
    sleep 5
  done
  return 1
}

# Só os serviços com mudança são recriados (db e redis não param sem motivo). O proxy é recriado sempre:
# o compose não detecta mudança em bind mount de arquivo (o git troca o inode) e o nginx guarda o IP do
# backend da subida anterior; sem recriar, serve config e upstream antigos.
# Recriar o renovador a cada deploy dispara uma renovação (ver deploy/https/renewer/entrypoint.sh).
# Opcional: falha aqui só avisa, nunca derruba o deploy da aplicação.
renew_certificates() {
  [ "$HTTPS_ENABLED" = true ] || return 0
  "${COMPOSE[@]}" up -d --no-deps --force-recreate cert-renewer \
    || echo "AVISO: cert-renewer não subiu; certificados não foram renovados neste deploy." >&2
}

bring_up() {
  "${COMPOSE[@]}" up -d --build --remove-orphans --wait || return 1
  "${COMPOSE[@]}" up -d --no-deps --force-recreate --wait "$DEPLOY_CFG_PROXY_SERVICE" || return 1
  renew_certificates
  wait_healthy
}

# Verificação de HTTPS só informativa: um domínio fora do ar (DNS ainda não propagado, por exemplo) não reverte o deploy.
check_https() {
  [ "$HTTPS_ENABLED" = true ] || return 0
  local domain code
  while read -r domain; do
    [ -n "$domain" ] || continue
    code=$(curl -sk --max-time 10 --resolve "$domain:443:127.0.0.1" -o /dev/null -w '%{http_code}' "https://$domain/" || true)
    if [ "$code" = 000 ] || [ -z "$code" ]; then
      echo "AVISO: https://$domain/ não respondeu (DNS apontando para o elastic_ip? porta 443 aberta?)." >&2
    else
      echo "HTTPS: https://$domain/ respondeu $code."
    fi
  done <<< "$(printf '%s' "$DEPLOY_CFG_HTTPS_DOMAINS" | tr ',' '\n' | cut -d= -f1)"
}

if bring_up; then
  # Imagens órfãs e cache de build com mais de 7 dias: sem isto o disco raiz enche a cada build.
  docker image prune -f >/dev/null
  docker builder prune -f --filter until=168h >/dev/null || true
  check_https
  echo "✅ Deploy concluído em $(git rev-parse --short HEAD); $DEPLOY_CFG_HEALTH_URL ok."
  exit 0
fi

echo "❌ Subida da stack ou health check falhou em $DEPLOY_CFG_HEALTH_URL." >&2
show_failed_logs

# Volta ao SHA anterior só se pedido e se ele for diferente do que acabou de falhar.
# Migrations de schema executadas pelo deploy NÃO são revertidas.
if [ "$AUTO_ROLLBACK" = true ] && [ "$PREVIOUS_SHA" != nenhum ] && [ "$PREVIOUS_SHA" != "$TARGET_SHA" ]; then
  echo "↩️  Rollback automático para $PREVIOUS_SHA." >&2
  checkout_sha "$PREVIOUS_SHA"
  write_https_env
  if bring_up; then
    echo "↩️  Rollback concluído: aplicação de volta em $PREVIOUS_SHA." >&2
  else
    echo "⚠️  Rollback também falhou: intervenção manual (./deploy.sh shell)." >&2
  fi
fi
exit 1
