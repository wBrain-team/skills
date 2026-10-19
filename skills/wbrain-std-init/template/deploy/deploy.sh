#!/bin/bash
# Operação da EC2 via SSM Session Manager (sem SSH). Requer aws CLI, session-manager-plugin e jq.
# Permissões IAM do operador: ssm:SendCommand, ssm:GetCommandInvocation, ssm:StartSession,
# ssm:TerminateSession, ssm:DescribeInstanceInformation, logs:GetLogEvents.
#   ./deploy.sh           menu interativo (sem instância online, só opções de infra)
#   ./deploy.sh setup     configura/atualiza o ambiente (Docker, Compose, git...)
#   ./deploy.sh deploy    atualiza a aplicação (git pull da branch do config.yaml, envs do Secrets Manager)
#   ./deploy.sh deploy --ref <tag|branch|sha>   implanta uma ref específica em vez da ponta da branch
#   ./deploy.sh pins      mostra os pins atuais da instância no formato do config.yaml (só leitura)
#   ./deploy.sh shell     abre shell interativo na instância
#   ./deploy.sh up        sobe/atualiza a infra (infra/infra-up.sh)
#   ./deploy.sh check     verifica drift (infra/infra-up.sh --check)
#   ./deploy.sh down      destrói a infra, preservando dados e o Elastic IP (infra/infra-down.sh)
#   ./deploy.sh purge     apaga os dados preservados (só sem instância; infra/infra-purge.sh)
set -euo pipefail
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DEPLOY_DIR/infra/infra-lib.sh"

# Limite do comando na instância (build incluso): passado disso, o SSM cancela e o log fica em /var/log.
REMOTE_TIMEOUT=3600

# Variáveis DEPLOY_CFG_* do operador, no formato `export VAR=valor` (valor com %q, seguro para o bash da instância).
remote_env_header() {
  local var
  for var in $(compgen -v DEPLOY_CFG_); do
    printf 'export %s=%q\n' "$var" "${!var}"
  done
}

# Imprime os eventos novos de um stream do CloudWatch desde a última chamada (token guardado na variável
# de nome $2) e avança o token. Stream ainda inexistente (comando sem saída até agora) não é erro.
cw_follow() {
  local stream=$1 token_var=$2 response token args
  while :; do
    args=(--log-group-name "$SSM_LOG_GROUP" --log-stream-name "$stream" --start-from-head --output json)
    [ -z "${!token_var}" ] || args+=(--next-token "${!token_var}")
    response=$(aws logs get-log-events "${args[@]}" 2>/dev/null) || return 0
    jq -j '.events[].message | if endswith("\n") then . else . + "\n" end' <<< "$response"
    token=$(jq -r .nextForwardToken <<< "$response")
    # Mesmo token devolvido = não há mais eventos por enquanto.
    [ "$token" != "${!token_var}" ] || return 0
    printf -v "$token_var" '%s' "$token"
    CW_STREAMED=true
  done
}

# Envia um script à instância, com o cabeçalho de variáveis, e mostra a saída; falha se o comando não terminar com sucesso.
# Tudo vai em base64 dentro do JSON: nenhum valor de configuração precisa de escape.
# A saída completa vem do CloudWatch Logs, ao vivo (a da API do SSM é cortada em ~24 KB). Sem o log group
# (infra anterior ao output ssm_log_group), cai na saída cortada do get-command-invocation.
run_remote() {
  local script=$1 title=$2
  local payload_b64 params command_id status cw_args=() stdout_token="" stderr_token=""
  payload_b64=$({ remote_env_header; cat "$script"; } | base64 | tr -d '\n')
  params=$(mktemp)
  # Roda a partir de um arquivo (não do stdin do bash): comandos como ssh/docker não consomem o script.
  # \\" no formato do printf vira \" no JSON (um \" sozinho viraria " e quebraria o JSON).
  # shellcheck disable=SC2016 # o $ do comando é literal no JSON: expande na instância, não aqui
  printf '{"commands":["f=$(mktemp); echo %s | base64 -d > \\"$f\\"; bash \\"$f\\"; rc=$?; rm -f \\"$f\\"; exit $rc"]}' \
    "$payload_b64" > "$params"

  SSM_LOG_GROUP=$(tf output -raw ssm_log_group 2>/dev/null || true)
  [ -z "$SSM_LOG_GROUP" ] || cw_args=(--cloud-watch-output-config "CloudWatchOutputEnabled=true,CloudWatchLogGroupName=$SSM_LOG_GROUP")
  CW_STREAMED=false

  command_id=$(aws ssm send-command --instance-ids "$INSTANCE_ID" \
    --document-name AWS-RunShellScript --comment "deploy.sh $title" \
    --parameters "file://$params" ${cw_args[@]+"${cw_args[@]}"} --query 'Command.CommandId' --output text)
  rm -f "$params"
  echo "$title (comando $command_id); pode levar alguns minutos..."
  local stream_prefix="$command_id/$INSTANCE_ID/aws-runShellScript"

  # `aws ssm wait` desiste em ~100s, menos que um build: faz polling até o comando terminar, com limite.
  deadline=$((SECONDS + REMOTE_TIMEOUT))
  while :; do
    status=$(aws ssm get-command-invocation --command-id "$command_id" --instance-id "$INSTANCE_ID" \
      --query 'Status' --output text 2>/dev/null || echo Pending)
    case "$status" in
      Pending | InProgress | Delayed)
        if [ "$SECONDS" -ge "$deadline" ]; then
          aws ssm cancel-command --command-id "$command_id" --instance-id "$INSTANCE_ID" >/dev/null 2>&1 || true
          echo "⏱️  Tempo limite de ${REMOTE_TIMEOUT}s excedido: comando cancelado (o log completo fica na instância)." >&2
          status=TimedOut
          break
        fi
        if [ -n "$SSM_LOG_GROUP" ]; then
          cw_follow "$stream_prefix/stdout" stdout_token
          cw_follow "$stream_prefix/stderr" stderr_token >&2
        fi
        sleep 5 ;;
      *) break ;;
    esac
  done
  if [ -n "$SSM_LOG_GROUP" ]; then
    # O agente envia o fim da saída alguns segundos depois do status final.
    sleep 5
    cw_follow "$stream_prefix/stdout" stdout_token
    cw_follow "$stream_prefix/stderr" stderr_token >&2
  fi
  if ! $CW_STREAMED; then
    aws ssm get-command-invocation --command-id "$command_id" --instance-id "$INSTANCE_ID" \
      --query 'StandardOutputContent' --output text
    aws ssm get-command-invocation --command-id "$command_id" --instance-id "$INSTANCE_ID" \
      --query 'StandardErrorContent' --output text >&2
  else
    echo "(saída completa no CloudWatch: $SSM_LOG_GROUP, streams $stream_prefix/*)"
  fi

  [ "$status" = "Success" ] || { echo "❌ Falhou (status: $status)." >&2; return 1; }
}

setup_environment() {
  load_remote_config || return 1
  run_remote "$DEPLOY_DIR/host-setup.sh" "Configurando ambiente" && echo "✅ Ambiente configurado."
}

deploy_application() {
  load_remote_config || return 1
  # shellcheck disable=SC2034 # lido por remote_env_header (compgen DEPLOY_CFG_), não por nome
  DEPLOY_CFG_SECRET=$(tf output -raw secret_name) || { echo "Output secret_name indisponível: rode ./deploy.sh up." >&2; return 1; }
  # shellcheck disable=SC2034 # lido por remote_env_header (compgen DEPLOY_CFG_), não por nome
  DEPLOY_CFG_REGION=$AWS_DEFAULT_REGION
  # shellcheck disable=SC2034 # lido por remote_env_header (compgen DEPLOY_CFG_), não por nome
  DEPLOY_CFG_REF=${REF:-}
  run_remote "$DEPLOY_DIR/remote-deploy.sh" "Deploy (${REF:-$DEPLOY_CFG_BRANCH})"
}

show_pins() {
  load_remote_config || return 1
  run_remote "$DEPLOY_DIR/pins.sh" "Pins atuais"
}

open_shell() {
  aws ssm start-session --target "$INSTANCE_ID"
}

run_action() {
  case "$1" in
    setup) setup_environment ;;
    deploy) deploy_application ;;
    pins) show_pins ;;
    shell) open_shell ;;
    up) "$DEPLOY_DIR/infra/infra-up.sh" ;;
    check) "$DEPLOY_DIR/infra/infra-up.sh" --check ;;
    down) "$DEPLOY_DIR/infra/infra-down.sh" ;;
    purge) "$DEPLOY_DIR/infra/infra-purge.sh" ;;
  esac
}

USAGE="Uso: $0 [setup|deploy [--ref <tag|branch|sha>]|pins|shell|up|check|down|purge]"
case "${1:-menu}" in setup | deploy | pins | shell | up | check | down | purge | menu) ;; *) echo "$USAGE" >&2; exit 64 ;; esac
REF=""
if [ "${2:-}" = "--ref" ]; then
  [ "$1" = deploy ] && [ -n "${3:-}" ] || { echo "$USAGE" >&2; exit 64; }
  REF=$3
elif [ $# -gt 1 ]; then
  echo "$USAGE" >&2; exit 64
fi

require_prereqs
require_aws_tools
tf_init

# Ações diretas: as de ambiente exigem instância online; as de infra rodam sempre.
if [ $# -gt 0 ]; then
  case "$1" in setup | deploy | pins | shell) resolve_target ;; esac
  rc=0
  run_action "$1" || rc=$?
  [ "$rc" -eq 0 ] || echo "❌ Ação $1 terminou com código $rc (saída acima)." >&2
  exit "$rc"
fi

# Menu dinâmico: sem instância online só aparecem as opções de infra.
while true; do
  refresh_target
  actions=(); labels=(); purge_available=false
  case "$INSTANCE_STATUS" in
    online)
      actions+=(setup deploy pins shell); labels+=("Configurar / atualizar ambiente" "Deploy da aplicação" "Ver pins atuais (versões para o config.yaml)" "Acessar shell") ;;
    offline)
      echo "⚠️  Instância $INSTANCE_ID existe, mas não está online no SSM (subindo? aguarde alguns minutos)." ;;
    none)
      echo "ℹ️  Nenhuma instância no state: só opções de infra."
      # Segunda etapa da remoção: só aparece depois que a infra foi destruída.
      if has_preserved_data; then
        echo "🔒 Ainda existem dados preservados (volume, secret, Elastic IP, backups)."
        purge_available=true
      fi ;;
  esac
  actions+=(up check down)
  labels+=("Subir / atualizar infra" "Verificar drift da infra" "Destruir infra")
  if $purge_available; then
    actions+=(purge); labels+=("Apagar dados preservados (IRREVERSÍVEL)")
  fi

  echo
  for i in "${!labels[@]}"; do echo "  $((i + 1))) ${labels[$i]}"; done
  echo "  0) Sair"
  read -r -p "Escolha uma opção: " choice
  [ "$choice" = "0" ] && break
  if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#actions[@]}" ]; then
    run_action "${actions[$((choice - 1))]}" || echo "❌ Ação terminou com código $? (saída acima)." >&2
  else
    echo "Opção inválida."
  fi
done
