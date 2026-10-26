#!/usr/bin/env bash
# Etapas 0 e 1 da wbrain-std:tuning: guarda de branch + diff de snapshots/.
# Uso: preflight.sh [--full] [--base REF]
#   --full      inclui o diff completo de snapshots/
#   --base REF  compara contra REF (ex.: commit de conclusão da última tuning) em vez da main/master
# Saída: 0 = há modificação | 1 = branch main/master ou erro | 3 = nada a implementar
#         4 = alterações fora de snapshots/ (sem tuning em andamento)
set -uo pipefail

SNAPSHOTS="snapshots"
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
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  echo "RECUSADO: branch atual é '$branch'. A tuning não roda na branch principal." >&2
  echo "Proponha uma branch (ex.: feat/<descrição>) e crie-a com o ok do tutor." >&2
  exit 1
fi

if [ -n "$base" ]; then
  git rev-parse --verify -q "$base^{commit}" >/dev/null || { echo "ERRO: base '$base' não encontrada." >&2; exit 1; }
else
  for ref in main master origin/main origin/master; do
    git rev-parse --verify -q "$ref" >/dev/null && { base=$ref; break; }
  done
  [ -n "$base" ] || { echo "ERRO: branch principal não encontrada (main, master, origin/main ou origin/master)." >&2; exit 1; }
fi

committed=$(git diff --name-status "$base"...HEAD -- "$SNAPSHOTS")
local_changes=$(git diff --name-status HEAD -- "$SNAPSHOTS")
untracked=$(git ls-files --others --exclude-standard -- "$SNAPSHOTS" | sed 's/^/??\t/')

state=".std/tuning/${branch//\//__}.md"
fingerprint=$( { git diff "$base" -- "$SNAPSHOTS"; git ls-files --others --exclude-standard -z -- "$SNAPSHOTS" | xargs -0 -r cat; } | git hash-object --stdin)

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

# A tuning só roda numa branch cujo diff contra a base é apenas de snapshots/.
# Com estado existente, o que está fora de snapshots/ é da própria tuning em andamento.
others=$(
  { git diff --name-only "$base"...HEAD -- . ":!$SNAPSHOTS" ":!.std"
    git diff --name-only HEAD -- . ":!$SNAPSHOTS" ":!.std"
    git ls-files --others --exclude-standard -- . ":!$SNAPSHOTS" ":!.std"; } | sort -u
)
if [ -n "$others" ] && [ ! -f "$state" ]; then
  echo
  echo "## Fora de $SNAPSHOTS/ (vs $base)"
  echo "$others"
  echo
  echo "RECUSADO: a branch tem alterações fora de $SNAPSHOTS/. A tuning só roda quando o diff contra $base é apenas de $SNAPSHOTS/." >&2
  exit 4
fi

if [ -z "$committed$local_changes$untracked" ]; then
  echo
  echo "SEM MODIFICAÇÃO: nenhuma alteração em $SNAPSHOTS/."
  exit 3
fi

echo
echo "## Estatística (branch + local)"
git diff --stat "$base" -- "$SNAPSHOTS" | tail -n 20

if [ $full -eq 1 ]; then
  echo
  echo "## Diff completo (branch + local, rastreados)"
  git diff "$base" -- "$SNAPSHOTS"
  if [ -n "$untracked" ]; then
    echo
    echo "## Conteúdo dos não rastreados"
    git ls-files --others --exclude-standard -- "$SNAPSHOTS" | while read -r f; do
      echo "### $f"; cat "$f"; echo
    done
  fi
fi
exit 0
