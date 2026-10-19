#!/bin/bash
# Destrói a infra de computação (EC2, EIP, SG, IAM da instância), PRESERVANDO:
# volume de dados, secret de environments, Elastic IP (o DNS aponta para ele) e a policy de backup (DLM)
# com seus snapshots. O EIP fica sem instância (a AWS cobra IP público ocioso) até o próximo up.
# Para apagar também estes, use infra-purge.sh (depois do down).
#   ./infra-down.sh          mostra o plan e exige digitar o nome do ambiente
#   ./infra-down.sh --yes    sem confirmação (automação)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/infra-lib.sh"

YES=false
[ "${1:-}" = "--yes" ] && YES=true

require_prereqs
tf_init

targets=()
while IFS= read -r address; do
  targets+=("-target=$address")
done < <(tf state list | grep -v '^data\.' | grep -Ev "$PROTECTED_RESOURCES_REGEX" || true)

[ "${#targets[@]}" -gt 0 ] || { echo "Nada a destruir."; exit 0; }

# Resumo dos recursos que continuam existindo (mostrado antes da confirmação e de novo ao final,
# já que a saída do destroy empurra o primeiro aviso para fora da tela).
print_preserved() {
  local preserved
  preserved=$(tf state list | grep -E "$PROTECTED_RESOURCES_REGEX" || true)
  echo
  echo "🔒 Preservados (continuam na AWS e no state): volume de dados (/ext-vol), secret de environments,"
  echo "   Elastic IP (o próximo up reutiliza o mesmo IP), policy de backup (DLM) e os snapshots diários"
  echo "   (estes últimos nem estão no state)."
  [ -z "$preserved" ] || echo "$preserved" | sed 's/^/     - /'
  echo "   Para apagá-los de vez: ./deploy.sh purge (disponível no menu depois que a infra for destruída)."
}

tf plan -destroy -input=false "${targets[@]}"
print_preserved

if ! $YES; then
  read -r -p "Digite o nome do ambiente ($ENVIRONMENT) para confirmar: " answer
  [ "$answer" = "$ENVIRONMENT" ] || { echo "Cancelado."; exit 1; }
fi

tf destroy -input=false -auto-approve "${targets[@]}"
print_preserved
