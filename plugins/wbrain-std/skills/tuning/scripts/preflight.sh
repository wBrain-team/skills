#!/usr/bin/env bash
# Etapas 0 e 1 da wbrain-std:tuning: guarda de branch + diff de snaps/.
# Uso: preflight.sh [--full] [--base REF]
#   --full      inclui o diff completo de snaps/
#   --base REF  compara contra REF (ex.: commit de conclusão da última tuning) em vez da branch base do .std/config.json
# Saída: 0 = há modificação | 1 = branch protegida (base/main/master), config ausente ou erro
#         3 = nada a implementar | 4 = alterações fora de snaps/ (sem tuning em andamento)
set -uo pipefail

SNAPS="snaps"
CONFIG="$(cd "$(dirname "$0")" && pwd)/../../shared/scripts/std-config.sh"
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
  echo "RECUSADO: HEAD destacado (sem branch). Faça checkout de uma branch que não seja a base." >&2
  exit 1
fi
protected=$(bash "$CONFIG" protected) || exit 1
if printf '%s\n' "$protected" | grep -qxF -- "$branch"; then
  echo "RECUSADO: branch atual é '$branch' (branch base/principal). A tuning não roda nela." >&2
  echo "Proponha uma branch (ex.: feat/<descrição>) e crie-a com o ok do tutor." >&2
  exit 1
fi

if [ -n "$base" ]; then
  git rev-parse --verify -q "$base^{commit}" >/dev/null || { echo "ERRO: base '$base' não encontrada." >&2; exit 1; }
else
  base=$(bash "$CONFIG" base-ref) || exit 1
fi

committed=$(git diff --name-status "$base"...HEAD -- "$SNAPS")
local_changes=$(git diff --name-status HEAD -- "$SNAPS")
untracked=$(git ls-files --others --exclude-standard -- "$SNAPS" | sed 's/^/??\t/')

state=".std/tuning/${branch//\//__}.md"
fingerprint=$( { git diff "$base" -- "$SNAPS"; git ls-files --others --exclude-standard -z -- "$SNAPS" | xargs -0 -r cat; } | git hash-object --stdin)

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

# A tuning só roda numa branch cujo diff contra a base é apenas de snaps/.
# Com estado existente, o que está fora de snaps/ é da própria tuning em andamento.
others=$(
  { git diff --name-only "$base"...HEAD -- . ":!$SNAPS" ":!.std"
    git diff --name-only HEAD -- . ":!$SNAPS" ":!.std"
    git ls-files --others --exclude-standard -- . ":!$SNAPS" ":!.std"; } | sort -u
)
if [ -n "$others" ] && [ ! -f "$state" ]; then
  echo
  echo "## Fora de $SNAPS/ (vs $base)"
  echo "$others"
  echo
  echo "RECUSADO: a branch tem alterações fora de $SNAPS/. A tuning só roda quando o diff contra $base é apenas de $SNAPS/." >&2
  exit 4
fi

if [ -z "$committed$local_changes$untracked" ]; then
  echo
  echo "SEM MODIFICAÇÃO: nenhuma alteração em $SNAPS/."
  exit 3
fi

echo
echo "## Estatística (branch + local)"
git diff --stat "$base" -- "$SNAPS" | tail -n 20

if [ $full -eq 1 ]; then
  echo
  echo "## Diff completo (branch + local, rastreados)"
  git diff "$base" -- "$SNAPS"
  if [ -n "$untracked" ]; then
    echo
    echo "## Conteúdo dos não rastreados"
    git ls-files --others --exclude-standard -- "$SNAPS" | while read -r f; do
      echo "### $f"; cat "$f"; echo
    done
  fi
fi
exit 0
