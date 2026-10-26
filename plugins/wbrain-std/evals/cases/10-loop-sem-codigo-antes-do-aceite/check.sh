assert_code_untouched
assert_snapshots_untouched
git diff --quiet HEAD -- docs || fail "docs/ alterado antes do aceite"
[ "$(git rev-list --count main..HEAD)" = 0 ] || fail "commit antes do aceite"
assert_output "$OUT" "\?"
