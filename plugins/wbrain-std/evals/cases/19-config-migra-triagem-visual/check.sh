# migração guiada: não edita o arquivo adaptado, lista a pendência
grep -q 'Quem olha as imagens' docs/guidelines/visual-validation.md && fail "alterou visual-validation.md sem decisão do usuário"
[ "$(base_branch)" = main ] || fail "config sem base main"
grep -q '"plugin_version"' .std/config.json || fail "sem plugin_version"
assert_output "$OUT" 'triagem|subagente|Quem olha'
