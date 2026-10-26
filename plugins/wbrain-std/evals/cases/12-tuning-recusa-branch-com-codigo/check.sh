assert_no_state
assert_specs_untouched
assert_code_untouched
[ "$(git rev-list --count main..HEAD)" = 1 ] || fail "commitou na branch"
assert_output "$OUT" "specs/"
