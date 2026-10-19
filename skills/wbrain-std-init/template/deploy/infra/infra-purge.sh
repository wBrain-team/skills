#!/bin/bash
# Apaga DEFINITIVAMENTE o que o infra-down.sh preserva: policy de backup (DLM) e sua role,
# volume de dados, secret de environments e Elastic IP. Os snapshots NUNCA são apagados (último recurso de recuperação).
# Só roda sem instância no state (rode o down antes).
#   ./infra-purge.sh    lista o que será apagado e exige duas confirmações
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/infra-lib.sh"

[ $# -eq 0 ] || { echo "Uso: $0" >&2; exit 64; }

require_prereqs
tf_init
export AWS_PAGER="" AWS_DEFAULT_REGION
AWS_DEFAULT_REGION=$(get_region)
command -v aws >/dev/null || { echo "aws CLI não encontrado" >&2; exit 1; }

[ -z "$(get_instance_id)" ] || {
  echo "Há uma instância no state: destrua a infra (down) antes de apagar os dados." >&2
  exit 1
}

# Valor do atributo `id` de um recurso do state; vazio se o recurso não está no state.
state_id() {
  { tf state show -no-color "$1" 2>/dev/null || true; } | awk '$1 == "id" { gsub(/"/, "", $3); print $3 }'
}

VOLUME_ID=$(state_id aws_ebs_volume.data)
SECRET_ARN=$(state_id aws_secretsmanager_secret.env)
EIP_ALLOCATION_ID=$(state_id aws_eip.this)
[ -n "$VOLUME_ID$SECRET_ARN$EIP_ALLOCATION_ID" ] || { echo "Nada a apagar: volume, secret e Elastic IP não estão no state."; exit 0; }

SNAPSHOT_COUNT=0
if [ -n "$VOLUME_ID" ]; then
  SNAPSHOT_COUNT=$(aws ec2 describe-snapshots --owner-ids self --filters "Name=volume-id,Values=$VOLUME_ID" \
    --query 'length(Snapshots)' --output text)
  VOLUME_STATE=$(aws ec2 describe-volumes --volume-ids "$VOLUME_ID" --query 'Volumes[0].State' --output text 2>/dev/null || echo gone)
  [ "$VOLUME_STATE" != "in-use" ] || { echo "O volume $VOLUME_ID ainda está anexado a uma instância." >&2; exit 1; }
fi

echo "⚠️  Serão apagados DEFINITIVAMENTE (sem recuperação):"
[ -z "$VOLUME_ID" ] || echo "   - volume de dados $VOLUME_ID (dados persistentes e código em /ext-vol)"
[ -z "$SECRET_ARN" ] || echo "   - secret de environments $SECRET_ARN"
if [ -n "$EIP_ALLOCATION_ID" ]; then
  EIP_ADDRESS=$(aws ec2 describe-addresses --allocation-ids "$EIP_ALLOCATION_ID" --query 'Addresses[0].PublicIp' --output text 2>/dev/null || echo "?")
  echo "   - Elastic IP $EIP_ADDRESS ($EIP_ALLOCATION_ID): o IP volta para a AWS; DNS apontando para ele deixa de funcionar"
fi
echo "   - policy de backup (DLM) e a role dela"
echo "🔒 Os snapshots ($SNAPSHOT_COUNT do volume) NÃO serão apagados e deixam de ter retenção automática:"
echo "   remova-os manualmente (console/CLI) quando não precisar mais deles."
echo

read -r -p "Digite o nome do ambiente ($ENVIRONMENT) para confirmar: " answer
[ "$answer" = "$ENVIRONMENT" ] || { echo "Cancelado."; exit 1; }
read -r -p "Digite APAGAR DADOS para confirmar: " answer
[ "$answer" = "APAGAR DADOS" ] || { echo "Cancelado."; exit 1; }

if [ -n "$SECRET_ARN" ]; then
  read -r -p "Salvar o conteúdo do secret em arquivo local antes de apagar? [s/N] " answer
  if [[ "$answer" =~ ^[sS]$ ]]; then
    backup_file="$INFRA_DIR/../config/$(basename "$SECRET_ARN" | sed 's/-[^-]*$//').env.backup"
    (umask 077; aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query SecretString --output text > "$backup_file")
    echo "Secret salvo em $backup_file (permissão 600, fora do git). Apague-o quando não precisar mais."
  fi
fi

# Primeiro a policy de backup: assim ela não cria um snapshot novo durante a limpeza (os existentes ficam).
dlm_targets=()
while IFS= read -r address; do
  dlm_targets+=("-target=$address")
done < <(tf state list | grep -E '^(aws_dlm_lifecycle_policy\.data|aws_iam_role_policy_attachment\.dlm|aws_iam_role\.dlm)$' || true)
if [ "${#dlm_targets[@]}" -gt 0 ]; then
  tf destroy -input=false -auto-approve "${dlm_targets[@]}"
fi

if [ -n "$VOLUME_ID" ]; then
  aws ec2 delete-volume --volume-id "$VOLUME_ID"
  echo "Volume $VOLUME_ID apagado."
  tf state rm aws_ebs_volume.data
fi

if [ -n "$SECRET_ARN" ]; then
  # Sem janela de recuperação: do contrário o nome fica reservado e recriar o ambiente falharia.
  aws secretsmanager delete-secret --secret-id "$SECRET_ARN" --force-delete-without-recovery >/dev/null
  echo "Secret apagado."
  tf state rm aws_secretsmanager_secret.env
fi

if [ -n "$EIP_ALLOCATION_ID" ]; then
  aws ec2 release-address --allocation-id "$EIP_ALLOCATION_ID"
  echo "Elastic IP liberado."
  tf state rm aws_eip.this
fi

echo "✅ Dados apagados (snapshots preservados). O ambiente pode ser recriado do zero com 'up'."
