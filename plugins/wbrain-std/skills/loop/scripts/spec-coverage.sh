#!/usr/bin/env bash
# Relaciona specs aos testes que as referenciam pelo marcador `# spec: specs/...` ou `// spec: specs/...`.
# Uso: spec-coverage.sh [arquivo-de-spec...]   (sem argumentos: todas as specs)
# Saída: sempre 0 (informativo).
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# "arquivo:linha spec" para cada marcador fora de specs/ e docs/
markers=$(
  git grep --untracked -noE '(#|//) spec: specs/[^[:space:]]+\.md' -- . ':!specs' ':!docs' 2>/dev/null \
    | sed -E 's/^([^:]+:[0-9]+):(#|\/\/) spec: /\1 /'
)
marker_files=$(
  git grep --untracked -loE '(#|//) spec: specs/[^[:space:]]+\.md' -- . ':!specs' ':!docs' 2>/dev/null
)

if [ $# -eq 0 ]; then
  specs=$(git ls-files --cached --others --exclude-standard -- 'specs/*.md' | grep -v '^specs/specs.md$')
else
  specs=$(printf '%s\n' "$@")
fi

missing=""
echo "Cobertura por spec:"
for s in $specs; do
  [ -e "$s" ] || continue
  n=$(
    for f in $marker_files; do
      grep -qE "(#|//) spec: $s([[:space:]]|$)" "$f" && echo "$f"
    done | sort -u | wc -l
  )
  echo "$s — $n arquivo(s) de teste"
  [ "$n" -eq 0 ] && missing="$missing$s"$'\n'
done

echo
echo "Specs sem teste:"
[ -n "$missing" ] && printf '%s' "$missing" || echo "(nenhuma)"

echo
echo "Marcadores apontando para spec inexistente:"
orphans=$(printf '%s\n' "$markers" | while read -r loc s; do
  [ -n "$s" ] && [ ! -e "$s" ] && echo "$loc -> $s"
done)
[ -n "$orphans" ] && echo "$orphans" || echo "(nenhum)"
exit 0
