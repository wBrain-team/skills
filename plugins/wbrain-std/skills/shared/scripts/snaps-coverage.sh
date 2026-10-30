#!/usr/bin/env bash
# Relaciona snaps aos testes que os referenciam pelo marcador `# snap: snaps/...` ou `// snap: snaps/...`.
# Uso: snaps-coverage.sh [arquivo-de-snap...]   (sem argumentos: todos os snaps)
# Saída: sempre 0 (informativo).
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# "arquivo:linha snap" para cada marcador fora de snaps/ e docs/
markers=$(
  git grep --untracked -noE '(#|//) snap: snaps/[^[:space:]]+\.md' -- . ':!snaps' ':!docs' 2>/dev/null \
    | sed -E 's/^([^:]+:[0-9]+):(#|\/\/) snap: /\1 /'
)
marker_files=$(
  git grep --untracked -loE '(#|//) snap: snaps/[^[:space:]]+\.md' -- . ':!snaps' ':!docs' 2>/dev/null
)

if [ $# -eq 0 ]; then
  snaps=$(git ls-files --cached --others --exclude-standard -- 'snaps/*.md' | grep -v '^snaps/snaps.md$')
else
  snaps=$(printf '%s\n' "$@")
fi

missing=""
echo "Cobertura por snap:"
for s in $snaps; do
  [ -e "$s" ] || continue
  n=$(
    for f in $marker_files; do
      grep -qE "(#|//) snap: $s([[:space:]]|$)" "$f" && echo "$f"
    done | sort -u | wc -l
  )
  echo "$s — $n arquivo(s) de teste"
  [ "$n" -eq 0 ] && missing="$missing$s"$'\n'
done

echo
echo "Snaps sem teste:"
[ -n "$missing" ] && printf '%s' "$missing" || echo "(nenhuma)"

echo
echo "Marcadores apontando para snap inexistente:"
orphans=$(printf '%s\n' "$markers" | while read -r loc s; do
  [ -n "$s" ] && [ ! -e "$s" ] && echo "$loc -> $s"
done)
[ -n "$orphans" ] && echo "$orphans" || echo "(nenhum)"
exit 0
