#!/usr/bin/env bash
# Roda os evals das skills wbrain-std com `claude -p`.
# Uso: evals/run.sh [filtro]   (filtro: parte do nome do caso, ex.: 03)
# Cada caso em cases/<nome>/: setup.sh (monta o repo), prompt.txt (o que o tutor digita), check.sh (asserções).
# Saída: 0 = todos passaram | 1 = algum falhou. Repos e saídas ficam em $EVAL_TMP (padrão: mktemp).
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
plugin=$(dirname "$here")
tmp=${EVAL_TMP:-$(mktemp -d)}
model_args=(); [ -n "${EVAL_MODEL:-}" ] && model_args=(--model "$EVAL_MODEL")
pass=0; failed=()

for case_dir in "$here"/cases/*/; do
  name=$(basename "$case_dir")
  [[ "$name" == *"${1:-}"* ]] || continue
  repo="$tmp/$name"; out="$tmp/$name.out"
  rm -rf "$repo"
  ( source "$here/lib.sh"; base_repo "$repo" && source "$case_dir/setup.sh" ) >/dev/null \
    || { failed+=("$name (setup)"); continue; }

  echo "▶ $name"
  ( cd "$repo" && timeout "${EVAL_TIMEOUT:-900}" claude -p "$(cat "$case_dir/prompt.txt")" \
      --plugin-dir "$plugin" --permission-mode acceptEdits \
      --allowedTools "Bash" "Read" "Write" "Edit" "Glob" "Grep" "Agent" "Skill" \
      --max-budget-usd "${EVAL_BUDGET:-3}" "${model_args[@]}" ) > "$out" 2>&1
  status=$?
  if [ $status -ne 0 ] || grep -q '^API Error' "$out"; then
    echo "  ✗ claude falhou (código $status; saída: $out)"; failed+=("$name (execução)"); continue
  fi

  if result=$(cd "$repo" && OUT="$out" bash -c "source '$here/lib.sh'; source '$case_dir/check.sh'" 2>&1); then
    echo "  ✓ passou"; pass=$((pass + 1))
  else
    echo "  ✗ $result (saída: $out)"; failed+=("$name")
  fi
done

echo
echo "Passaram: $pass | Falharam: ${#failed[@]}"
for f in "${failed[@]}"; do echo "  - $f"; done
echo "Artefatos: $tmp"
[ ${#failed[@]} -eq 0 ]
