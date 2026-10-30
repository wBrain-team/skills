assert_no_state
assert_snaps_untouched
assert_code_untouched
[ "$(git rev-list --count "$(base_branch)"..HEAD)" = 1 ] || fail "commitou na branch"
assert_output "$OUT" "snaps/"
