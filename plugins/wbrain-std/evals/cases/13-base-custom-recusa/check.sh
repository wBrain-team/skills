assert_no_state
assert_snaps_untouched
assert_code_untouched
[ "$(git branch --show-current)" = develop ] || fail "trocou de branch sem ok"
assert_output "$OUT" "branch"
