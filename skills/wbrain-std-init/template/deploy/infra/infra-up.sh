#!/bin/bash
# Sobe/atualiza a infra e verifica drift.
#   ./infra-up.sh            plan + confirmação + apply
#   ./infra-up.sh --check    só verifica drift (exit 0 = sem mudanças, 2 = há mudanças)
#   ./infra-up.sh --yes      aplica sem pedir confirmação
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/infra-lib.sh"

CHECK=false; YES=false
for arg in "$@"; do
  case "$arg" in
    --check) CHECK=true ;;
    --yes) YES=true ;;
    *) echo "Uso: $0 [--check] [--yes]" >&2; exit 64 ;;
  esac
done

require_prereqs
tf_init
tf validate

rc=0
tf plan -input=false -detailed-exitcode -out=tfplan || rc=$?
if [ "$rc" -eq 0 ]; then echo "✅ Infra em dia, sem drift."; exit 0; fi
[ "$rc" -eq 2 ] || { echo "❌ Falha no plan." >&2; exit 1; }

if $CHECK; then echo "⚠️  Há diferenças entre o código e a infra real."; exit 2; fi

if ! $YES; then
  read -r -p "Aplicar as mudanças acima? [s/N] " answer
  [[ "$answer" =~ ^[sSyY]$ ]] || { echo "Cancelado."; rm -f "$INFRA_DIR/tfplan"; exit 1; }
fi

tf apply -input=false tfplan
rm -f "$INFRA_DIR/tfplan"
tf output
