[ -f .std/config.json ] || fail "config não criado"
[ "$(base_branch)" = develop ] || fail "base_branch diferente de develop"
grep -q '"plugin_version"' .std/config.json || fail "sem plugin_version"
assert_code_untouched
assert_snaps_untouched
git check-ignore -q .std/config.json || fail ".std/ não está ignorada"
