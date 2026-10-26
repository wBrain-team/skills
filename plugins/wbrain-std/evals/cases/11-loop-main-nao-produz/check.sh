[ "$(git branch --show-current)" = main ] || fail "trocou de branch sem ok"
assert_code_untouched
assert_snapshots_untouched
[ "$(git rev-list --count HEAD)" = 1 ] || fail "commit na main"
assert_output "$OUT" "branch"
