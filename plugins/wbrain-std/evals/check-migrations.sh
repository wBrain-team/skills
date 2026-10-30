#!/usr/bin/env bash
# Falha se a versão atual do plugin pede migração ("Projetos existentes precisam" no CHANGELOG)
# sem uma entrada "## <versão>" em skills/shared/migrations.md.
set -uo pipefail
plugin=$(cd "$(dirname "$0")/.." && pwd)
root=$(cd "$plugin/../.." && pwd)
version=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$plugin/.claude-plugin/plugin.json" | head -n 1)
[ -n "$version" ] || { echo "ERRO: versão não encontrada em plugin.json." >&2; exit 1; }
section=$(awk -v v="## $version" '$0 == v {f=1; next} /^## / {f=0} f' "$root/CHANGELOG.md")
[ -n "$section" ] || { echo "ERRO: CHANGELOG.md sem a seção '## $version'." >&2; exit 1; }
if grep -q 'Projetos existentes precisam' <<<"$section"; then
  grep -qE "^## $version( |$)" "$plugin/skills/shared/migrations.md" \
    || { echo "ERRO: o CHANGELOG da $version pede migração, mas falta '## $version' em skills/shared/migrations.md." >&2; exit 1; }
fi
echo "migrações ok ($version)"
