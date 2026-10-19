#!/usr/bin/env bash
# Lista links Markdown internos quebrados em docs/ (ou nos caminhos passados).
# Uso: check-doc-links.sh [caminho...]   Saída: 0 = ok | 1 = há links quebrados
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ $# -eq 0 ] && set -- docs

broken=$(
  find "$@" -name '*.md' -print0 | while IFS= read -r -d '' md; do
    dir=$(dirname "$md")
    grep -noE '\]\([^)[:space:]]+\)' "$md" | while IFS= read -r hit; do
      line=${hit%%:*}
      target=${hit#*](}; target=${target%)}; target=${target%%#*}
      case "$target" in ''|http://*|https://*|mailto:*) continue ;; esac
      [ -e "$dir/$target" ] || echo "$md:$line -> $target"
    done
  done
)

if [ -n "$broken" ]; then
  echo "Links quebrados:"; echo "$broken"; exit 1
fi
echo "OK: nenhum link interno quebrado."
