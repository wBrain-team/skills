#!/bin/bash
# Helper compartilhado: usa o terraform e o aws CLI instalados no ambiente do operador.
set -euo pipefail

INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_MIN_VERSION="1.10" # backend s3 com use_lockfile

# Sem env vars nem ~/.aws, pergunta no terminal; ficam só nesta execução (não são gravadas).
prompt_aws_credentials_if_missing() {
  if [ -n "${AWS_ACCESS_KEY_ID:-}" ] || [ -d "$HOME/.aws" ]; then
    return
  fi
  [ -t 0 ] || { echo "Credenciais AWS não encontradas (AWS_ACCESS_KEY_ID ou ~/.aws)" >&2; exit 1; }

  echo "Credenciais AWS não encontradas; informe-as (valem só para esta execução)."
  read -r -p "AWS_ACCESS_KEY_ID: " AWS_ACCESS_KEY_ID
  read -r -s -p "AWS_SECRET_ACCESS_KEY: " AWS_SECRET_ACCESS_KEY; echo
  read -r -s -p "AWS_SESSION_TOKEN (opcional, Enter para pular): " AWS_SESSION_TOKEN; echo
  [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ] || { echo "Credenciais vazias." >&2; exit 1; }
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
  [ -n "$AWS_SESSION_TOKEN" ] && export AWS_SESSION_TOKEN || unset AWS_SESSION_TOKEN
}

# Recursos que o infra-down.sh NUNCA destrói (dados e backups); só remoção manual.
# O Elastic IP também: recriá-lo trocaria o IP público e quebraria o DNS dos domínios.
PROTECTED_RESOURCES_REGEX='^(aws_ebs_volume\.data|aws_secretsmanager_secret\.env|aws_eip\.this|aws_dlm_lifecycle_policy\.data|aws_iam_role\.dlm|aws_iam_role_policy_attachment\.dlm)$'

CONFIG_FILE="$INFRA_DIR/../config/config.yaml"

# Lê chaves do config.yaml (YAML simples): `config_get chave` (topo) ou `config_get state bucket`.
config_get() {
  local section="" key="$1"
  [ $# -eq 2 ] && { section="$1"; key="$2"; }
  if [ -n "$section" ]; then
    sed -n "/^$section:/,/^[^ #]/p" "$CONFIG_FILE" | sed -n "s/^[[:space:]]\+$key:[[:space:]]*//p"
  else
    sed -n "s/^$key:[[:space:]]*//p" "$CONFIG_FILE"
  fi | head -1 | sed -e 's/[[:space:]]*#.*//' -e "s/^[\"']//" -e "s/[\"']\$//"
}

# Valida o subconjunto de YAML que config_get entende: `chave: valor` no topo, seções com filhos indentados
# em 2 espaços, sem tab e sem chave repetida. Sem isto, um formato não suportado seria lido em silêncio errado.
# Único formato extra: lista de objetos sob uma chave de seção com valor vazio (ver config_list).
config_validate() {
  awk '
    /^[ ]*\t/ { printf "linha %d: tab na indentação\n", NR; bad = 1; next }
    /^[ ]*(#.*)?$/ { next }
    /^[A-Za-z_][A-Za-z0-9_]*:/ {
      key = $0; sub(/:.*/, "", key)
      if (key in seen) { printf "linha %d: chave duplicada %s\n", NR, key; bad = 1 }
      seen[key] = 1
      section = ($0 ~ /^[A-Za-z_][A-Za-z0-9_]*:[ ]*(#.*)?$/) ? key : ""
      inlist = 0
      next
    }
    /^  [A-Za-z_][A-Za-z0-9_]*:/ {
      if (section == "") { printf "linha %d: chave indentada fora de seção\n", NR; bad = 1; next }
      key = $0; sub(/^  /, "", key); sub(/:.*/, "", key)
      if ((section "." key) in seen) { printf "linha %d: chave duplicada %s.%s\n", NR, section, key; bad = 1 }
      seen[section "." key] = 1
      inlist = ($0 ~ /^  [A-Za-z_][A-Za-z0-9_]*:[ ]*(#.*)?$/) ? 1 : 0
      items = 0
      next
    }
    /^    - [A-Za-z_][A-Za-z0-9_]*:/ {
      if (!inlist) { printf "linha %d: lista fora de chave de seção vazia\n", NR; bad = 1; next }
      items++
      key = $0; sub(/^    - /, "", key); sub(/:.*/, "", key)
      if ((items SUBSEP key) in itemseen) { printf "linha %d: chave duplicada %s no item\n", NR, key; bad = 1 }
      itemseen[items, key] = 1
      inlist = 2
      next
    }
    /^      [A-Za-z_][A-Za-z0-9_]*:/ {
      if (inlist != 2) { printf "linha %d: continuação de item sem traço\n", NR; bad = 1; next }
      key = $0; sub(/^      /, "", key); sub(/:.*/, "", key)
      if ((items SUBSEP key) in itemseen) { printf "linha %d: chave duplicada %s no item\n", NR, key; bad = 1 }
      itemseen[items, key] = 1
      next
    }
    { printf "linha %d: formato não suportado (use chave: valor; filhos de seção com 2 espaços)\n", NR; bad = 1 }
    END { exit bad }
  ' "$1" >&2
}

# Lista de objetos de uma seção (`  chave:` seguido de `    - a: x` / `      b: y`): uma linha por item,
# campos na ordem do arquivo separados por `|`. Valores sem aspas nem comentário inline.
config_list() {
  local file=$1 section=$2 key=$3
  awk -v section="$section" -v key="$key" '
    function value(line) {
      sub(/^[^:]*:[ ]*/, "", line); sub(/[ ]*#.*$/, "", line); gsub(/^[\"\047]|[\"\047]$/, "", line)
      return line
    }
    /^[A-Za-z_][A-Za-z0-9_]*:/ { in_section = ($0 ~ "^" section ":"); in_list = 0; next }
    in_section && $0 ~ "^  " key ":" { in_list = 1; next }
    in_list && /^    - / {
      if (item != "") print item
      line = $0; sub(/^    - /, "", line); item = value(line)
      next
    }
    in_list && /^      [A-Za-z_]/ {
      line = $0; sub(/^      /, "", line); item = item "|" value(line)
      next
    }
    END { if (item != "") print item }
  ' "$file"
}

# Regras do bloco https (só com https.enabled: true): email, domínios válidos, destino host:porta, sem repetidos.
config_https_check() {
  [ "$(config_get https enabled)" = true ] || return 0
  local errors=() email renew_day domains_list domain upstream port seen_domains=""
  email=$(config_get https email)
  [[ "$email" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]] || errors+=("https.email ausente ou inválido")
  renew_day=$(config_get https renew_day)
  [[ "${renew_day:-1}" =~ ^[0-9]+$ ]] && [ "${renew_day:-1}" -ge 1 ] && [ "${renew_day:-1}" -le 28 ] \
    || errors+=("https.renew_day fora de 1-28: $renew_day")
  domains_list=$(config_list "$CONFIG_FILE" https domains)
  [ -n "$domains_list" ] || errors+=("https.domains vazio")
  while IFS='|' read -r domain upstream; do
    [ -n "$domain" ] || continue
    [[ "$domain" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$ ]] || errors+=("domínio inválido: $domain")
    case " $seen_domains " in *" $domain "*) errors+=("domínio duplicado: $domain") ;; esac
    seen_domains="$seen_domains $domain"
    port=${upstream##*:}
    [[ "$upstream" == *:* && "$port" =~ ^[0-9]+$ && "$port" -ge 1 && "$port" -le 65535 && -n "${upstream%:*}" ]] \
      || errors+=("destino inválido para $domain: '${upstream:-vazio}' (use servico:porta)")
  done <<< "$domains_list"
  [ "${#errors[@]}" -eq 0 ] || { printf 'https: %s\n' "${errors[@]}" >&2; return 1; }
}

# name, environment e suffix entram em nomes de recursos AWS e em caminhos na instância (log, deploy key, lock):
# só minúsculas, dígitos e hífen. O prefixo <name>-<environment>[-suffix] cabe em 60 caracteres porque a role
# do DLM (<prefixo>-dlm) tem limite de 64 no IAM.
NAME_MAX_PREFIX=60
config_names_check() {
  local errors=() key value prefix
  for key in name environment suffix; do
    value=$(config_get "$key")
    [ -n "$value" ] || continue
    [[ "$value" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || errors+=("$key inválido: '$value' (use minúsculas, dígitos e hífen, sem hífen nas pontas)")
  done
  prefix="$(config_get name)-$(config_get environment)"
  [ -z "$(config_get suffix)" ] || prefix="$prefix-$(config_get suffix)"
  [ "${#prefix}" -le "$NAME_MAX_PREFIX" ] || errors+=("prefixo '$prefix' tem ${#prefix} caracteres (máximo $NAME_MAX_PREFIX)")
  [ "${#errors[@]}" -eq 0 ] || { printf '%s\n' "${errors[@]}" >&2; return 1; }
}

load_config() {
  [ -f "$CONFIG_FILE" ] || {
    echo "Crie $CONFIG_FILE a partir de config.yaml.example" >&2
    exit 1
  }
  config_validate "$CONFIG_FILE" || { echo "config.yaml inválido (ver linhas acima)." >&2; exit 1; }
  config_https_check || { echo "config.yaml inválido na seção https (ver linhas acima)." >&2; exit 1; }
  config_names_check || { echo "config.yaml inválido em name/environment/suffix (ver linhas acima)." >&2; exit 1; }
  NAME=$(config_get name); ENVIRONMENT=$(config_get environment); SUFFIX=$(config_get suffix)
  STATE_BUCKET=$(config_get state bucket); STATE_KEY=$(config_get state key); STATE_REGION=$(config_get state region)
  [ -n "$NAME" ] && [ -n "$ENVIRONMENT" ] && [ -n "$STATE_BUCKET" ] && [ -n "$STATE_KEY" ] && [ -n "$STATE_REGION" ] || {
    echo "config.yaml precisa de name, environment, state.bucket, state.key e state.region" >&2
    exit 1
  }
  export TF_VAR_name="$NAME" TF_VAR_environment="$ENVIRONMENT" TF_VAR_suffix="$SUFFIX"
  local https_enabled; https_enabled=$(config_get https enabled)
  export TF_VAR_https_enabled="${https_enabled:-false}"
}

# Há dados preservados (volume/secret/backup) no state? Usa variável: `grep -q` num pipe com pipefail daria falso negativo.
has_preserved_data() {
  local preserved
  preserved=$(tf state list 2>/dev/null | grep -E "$PROTECTED_RESOURCES_REGEX" || true)
  [ -n "$preserved" ]
}

# Configuração que os scripts da instância consomem, como variáveis DEPLOY_CFG_* (o deploy.sh as envia no cabeçalho
# do script remoto; ver remote_env_header). Valores faltantes abortam antes de qualquer comando na instância.
# shellcheck disable=SC2034 # as DEPLOY_CFG_* são lidas por deploy.sh via compgen, não por nome neste arquivo
load_remote_config() {
  DEPLOY_CFG_NAME=$NAME
  DEPLOY_CFG_REPO=$(config_get deploy repo); DEPLOY_CFG_BRANCH=$(config_get deploy branch)
  DEPLOY_CFG_APP_DIR=$(config_get app dir); DEPLOY_CFG_COMPOSE_FILES=$(config_get app compose_files)
  DEPLOY_CFG_ENV_FILE=$(config_get app env_file); DEPLOY_CFG_DATA_DIRS=$(config_get app data_dirs)
  DEPLOY_CFG_PROXY_SERVICE=$(config_get app proxy_service)
  DEPLOY_CFG_HEALTH_URL=$(config_get app health_url); DEPLOY_CFG_HEALTH_TIMEOUT=$(config_get app health_timeout)
  DEPLOY_CFG_AUTO_ROLLBACK=$(config_get deploy auto_rollback) # opcional: vazio = false
  DEPLOY_CFG_GIT_HOST_FINGERPRINT=$(config_get host git_host_fingerprint)
  DEPLOY_CFG_DOCKER_VERSION=$(config_get host docker_version) # opcionais: vazio = sem pin
  DEPLOY_CFG_AWSCLI_VERSION=$(config_get host awscli_version); DEPLOY_CFG_AWSCLI_SHA256=$(config_get host awscli_sha256)
  # HTTPS opcional: DOMAINS vira `dominio=servico:porta,...` (uma entrada por domínio, na ordem do config.yaml).
  DEPLOY_CFG_HTTPS_ENABLED=$(config_get https enabled); DEPLOY_CFG_HTTPS_ENABLED=${DEPLOY_CFG_HTTPS_ENABLED:-false}
  DEPLOY_CFG_HTTPS_EMAIL=$(config_get https email); DEPLOY_CFG_HTTPS_STAGING=$(config_get https staging)
  DEPLOY_CFG_HTTPS_RENEW_DAY=$(config_get https renew_day); DEPLOY_CFG_HTTPS_RENEW_DAY=${DEPLOY_CFG_HTTPS_RENEW_DAY:-1}
  DEPLOY_CFG_HTTPS_DOMAINS=$(config_list "$CONFIG_FILE" https domains | awk -F'|' '{ printf "%s%s=%s", (NR > 1 ? "," : ""), $1, $2 }')
  local var missing=()
  for var in DEPLOY_CFG_NAME DEPLOY_CFG_REPO DEPLOY_CFG_BRANCH DEPLOY_CFG_APP_DIR DEPLOY_CFG_COMPOSE_FILES DEPLOY_CFG_ENV_FILE DEPLOY_CFG_DATA_DIRS DEPLOY_CFG_PROXY_SERVICE DEPLOY_CFG_HEALTH_URL DEPLOY_CFG_HEALTH_TIMEOUT DEPLOY_CFG_GIT_HOST_FINGERPRINT; do
    [ -n "${!var}" ] || missing+=("$var")
  done
  [ "${#missing[@]}" -eq 0 ] || {
    echo "config.yaml incompleto: faltam ${missing[*]} (ver config.yaml.example)" >&2
    return 1
  }
}

require_prereqs() {
  require_terraform
  load_config
  prompt_aws_credentials_if_missing
}

require_terraform() {
  command -v terraform >/dev/null || { echo "terraform não encontrado" >&2; exit 1; }
  local version
  version=$(terraform version | head -1 | sed 's/[^0-9.]//g')
  [ "$(printf '%s\n%s\n' "$TF_MIN_VERSION" "$version" | sort -V | head -1)" = "$TF_MIN_VERSION" ] || {
    echo "terraform $version é antigo; exige >= $TF_MIN_VERSION" >&2
    exit 1
  }
}

# Executa o terraform em deploy/infra; credenciais AWS e TF_VAR_* são herdadas do ambiente.
# As variáveis opcionais ficam em config/terraform.tfvars (o Terraform só carrega sozinho o da própria pasta).
# Só plan/destroy as recebem: o apply do plano salvo (tfplan) já as traz e recusa -var-file.
tf() {
  local tfvars="$INFRA_DIR/../config/terraform.tfvars" extra=()
  case "${1:-}" in plan | destroy) [ ! -f "$tfvars" ] || extra=("-var-file=$tfvars") ;; esac
  (cd "$INFRA_DIR" && TF_IN_AUTOMATION=1 terraform "${1:-}" ${extra[@]+"${extra[@]}"} "${@:2}")
}

# Se existir state local com recursos (uso anterior), migra para o bucket.
tf_init() {
  local mode=(-reconfigure)
  if grep -q '"type"' "$INFRA_DIR/terraform.tfstate" 2>/dev/null; then
    mode=(-migrate-state -force-copy)
  fi
  # A saída só aparece se o init falhar: senão o set -e encerra o script sem mensagem.
  local output
  output=$(tf init -input=false "${mode[@]}" \
    -backend-config="bucket=$STATE_BUCKET" \
    -backend-config="key=$STATE_KEY" \
    -backend-config="region=$STATE_REGION" 2>&1) || {
    echo "$output" >&2
    echo "❌ terraform init falhou (backend: s3://$STATE_BUCKET/$STATE_KEY)." >&2
    return 1
  }
}

# --- Acesso à EC2 (SSM Session Manager; a instância não tem porta de entrada) ---

require_aws_tools() {
  export AWS_PAGER="" # sem less: a saída do aws CLI vai direto ao terminal
  command -v aws >/dev/null || { echo "aws CLI não encontrado" >&2; exit 1; }
  command -v jq >/dev/null || { echo "jq não encontrado (lê a saída dos comandos no CloudWatch)" >&2; exit 1; }
  command -v session-manager-plugin >/dev/null || {
    echo "session-manager-plugin não encontrado (necessário para o shell interativo)." >&2
    echo "Instalação: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html" >&2
    exit 1
  }
}

# Região do provider (output do Terraform); antes do 1º apply com o output, cai no padrão do projeto.
get_region() {
  tf output -raw aws_region 2>/dev/null || echo "${AWS_REGION:-${AWS_DEFAULT_REGION:-sa-east-1}}"
}

# Lê do state (não dos outputs): após o destroy por -target os outputs ficam desatualizados,
# enquanto o state deixa de ter o recurso. Vazio se não há instância.
get_instance_id() {
  # `|| true`: sem a instância o `state show` falha e, com pipefail/set -e, o script morreria em silêncio.
  { tf state show -no-color aws_instance.this 2>/dev/null || true; } \
    | awk '$1 == "id" { gsub(/"/, "", $3); print $3 }'
}

# Define INSTANCE_ID, AWS_DEFAULT_REGION e INSTANCE_STATUS:
#   none (sem instância no state) | offline (existe, mas não está online no SSM) | online
refresh_target() {
  INSTANCE_ID=$(get_instance_id)
  export AWS_DEFAULT_REGION
  AWS_DEFAULT_REGION=$(get_region)

  if [ -z "$INSTANCE_ID" ]; then
    INSTANCE_STATUS=none
    return
  fi
  local ping
  ping=$(aws ssm describe-instance-information \
    --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
    --query 'InstanceInformationList[0].PingStatus' --output text) || {
    echo "Falha ao consultar o SSM (credenciais/permissão ssm:DescribeInstanceInformation?)." >&2
    exit 1
  }
  if [ "$ping" = "Online" ]; then INSTANCE_STATUS=online; else INSTANCE_STATUS=offline; fi
}

# Versão estrita (ações diretas): exige instância online no SSM.
resolve_target() {
  refresh_target
  case "$INSTANCE_STATUS" in
    none) echo "Instância não encontrada no state. Rode ./deploy.sh up antes." >&2; exit 1 ;;
    offline)
      echo "Instância $INSTANCE_ID ainda não está online no SSM." >&2
      echo "Se acabou de subir, aguarde alguns minutos e tente de novo." >&2
      exit 1 ;;
  esac
}
