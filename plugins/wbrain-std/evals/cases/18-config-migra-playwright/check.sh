# migração guiada: não cria nada sozinha, lista as pendências
[ ! -f docs/guidelines/visual-validation.md ] || fail "criou visual-validation.md sem decisão do usuário"
[ ! -f docs/testing/visual.md ] || fail "criou visual.md sem decisão do usuário"
[ ! -d src-frontend/e2e ] || fail "criou o cliente e2e sem decisão do usuário"
[ "$(base_branch)" = main ] || fail "config sem base main"
grep -q '"plugin_version"' .std/config.json || fail "sem plugin_version"
assert_output "$OUT" 'Playwright|navegador|visual'
