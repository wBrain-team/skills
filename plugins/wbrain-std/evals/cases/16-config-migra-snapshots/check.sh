[ ! -d snapshots ] || fail "snapshots/ ainda existe"
[ -f snaps/snaps.md ] || fail "snaps/snaps.md ausente"
grep -q '# snap:' tests/test_pedidos.py || fail "marcador do teste não migrado"
if grep -rnE 'snapshots?/|snapshots\.md|# snapshot:' AGENTS.md docs snaps tests; then fail "referências antigas restantes no conteúdo"; fi
grep -q 'snaps/' AGENTS.md || fail "AGENTS.md não referencia snaps/"
[ "$(base_branch)" = main ] || fail "config sem base main"
grep -q '"plugin_version"' .std/config.json || fail "sem plugin_version"
