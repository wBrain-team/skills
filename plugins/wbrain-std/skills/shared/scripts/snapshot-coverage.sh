#!/usr/bin/env bash
# Relaciona snapshots aos testes que os referenciam pelo marcador `# snapshot: snapshots/...` ou `// snapshot: snapshots/...`.
# Uso: snapshot-coverage.sh [arquivo-de-snapshot...]   (sem argumentos: todos os snapshots)
# Saída: sempre 0 (informativo).
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# "arquivo:linha snapshot" para cada marcador fora de snapshots/ e docs/
markers=$(
  git grep --untracked -noE '(#|//) snapshot: snapshots/[^[:space:]]+\.md' -- . ':!snapshots' ':!docs' 2>/dev/null \
    | sed -E 's/^([^:]+:[0-9]+):(#|\/\/) snapshot: /\1 /'
)
marker_files=$(
  git grep --untracked -loE '(#|//) snapshot: snapshots/[^[:space:]]+\.md' -- . ':!snapshots' ':!docs' 2>/dev/null
)

if [ $# -eq 0 ]; then
  snapshots=$(git ls-files --cached --others --exclude-standard -- 'snapshots/*.md' | grep -v '^snapshots/snapshots.md$')
else
  snapshots=$(printf '%s\n' "$@")
fi

missing=""
echo "Cobertura por snapshot:"
for s in $snapshots; do
  [ -e "$s" ] || continue
  n=$(
    for f in $marker_files; do
      grep -qE "(#|//) snapshot: $s([[:space:]]|$)" "$f" && echo "$f"
    done | sort -u | wc -l
  )
  echo "$s — $n arquivo(s) de teste"
  [ "$n" -eq 0 ] && missing="$missing$s"$'\n'
done

echo
echo "Snapshots sem teste:"
[ -n "$missing" ] && printf '%s' "$missing" || echo "(nenhuma)"

echo
echo "Marcadores apontando para snapshot inexistente:"
orphans=$(printf '%s\n' "$markers" | while read -r loc s; do
  [ -n "$s" ] && [ ! -e "$s" ] && echo "$loc -> $s"
done)
[ -n "$orphans" ] && echo "$orphans" || echo "(nenhum)"
exit 0
