#!/usr/bin/env bash
# Etapas 0 e 1 do wbrain-std-loop: guarda de branch + diff de specs/.
# Uso: preflight.sh [--full] [--base REF]
#   --full      inclui o diff completo de specs/
#   --base REF  compara contra REF (ex.: commit de conclusão do último loop) em vez da main
# Saída: 0 = há modificação | 1 = branch main/erro | 3 = nada a implementar
set -uo pipefail

SPECS="specs"
full=0; base=""
while [ $# -gt 0 ]; do
  case "$1" in
    --full) full=1 ;;
    --base) base="${2:-}"; shift ;;
    *) echo "ERRO: opção desconhecida: $1" >&2; exit 1 ;;
  esac
  shift
done
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "ERRO: não é um repositório git." >&2; exit 1; }

branch=$(git branch --show-current)
if [ -z "$branch" ]; then
  echo "RECUSADO: HEAD destacado (sem branch). Faça checkout de uma branch que não seja main." >&2
  exit 1
fi
if [ "$branch" = "main" ]; then
  echo "RECUSADO: branch atual é 'main'. O loop não roda na main." >&2
  echo "Crie uma branch (ex.: feat/<descrição>) ou peça explicitamente ao agente para criar uma branch com nome definido." >&2
  exit 1
fi

if [ -n "$base" ]; then
  git rev-parse --verify -q "$base^{commit}" >/dev/null || { echo "ERRO: base '$base' não encontrada." >&2; exit 1; }
elif git rev-parse --verify -q main >/dev/null; then
  base=main
elif git rev-parse --verify -q origin/main >/dev/null; then
  base=origin/main
else
  echo "ERRO: branch 'main' não encontrada (nem local nem origin/main)." >&2
  exit 1
fi

committed=$(git diff --name-status "$base"...HEAD -- "$SPECS")
local_changes=$(git diff --name-status HEAD -- "$SPECS")
untracked=$(git ls-files --others --exclude-standard -- "$SPECS" | sed 's/^/??\t/')

state=".std/loop/${branch//\//__}.md"
fingerprint=$( { git diff "$base" -- "$SPECS"; git ls-files --others --exclude-standard -z -- "$SPECS" | xargs -0 -r cat; } | git hash-object --stdin)

echo "branch: $branch"
echo "base: $base"
echo "fingerprint: $fingerprint"
if [ -f "$state" ]; then echo "state: $state (existe)"; else echo "state: $state (novo)"; fi
echo
echo "## Commitado na branch (vs $base)"
echo "${committed:-(nada)}"
echo
echo "## Alterações locais (staged + unstaged)"
echo "${local_changes:-(nada)}"
echo
echo "## Não rastreados"
echo "${untracked:-(nada)}"

if [ -z "$committed$local_changes$untracked" ]; then
  echo
  echo "SEM MODIFICAÇÃO: nenhuma alteração em $SPECS/."
  exit 3
fi

echo
echo "## Estatística (branch + local)"
git diff --stat "$base" -- "$SPECS" | tail -n 20

if [ $full -eq 1 ]; then
  echo
  echo "## Diff completo (branch + local, rastreados)"
  git diff "$base" -- "$SPECS"
  if [ -n "$untracked" ]; then
    echo
    echo "## Conteúdo dos não rastreados"
    git ls-files --others --exclude-standard -- "$SPECS" | while read -r f; do
      echo "### $f"; cat "$f"; echo
    done
  fi
fi
exit 0
