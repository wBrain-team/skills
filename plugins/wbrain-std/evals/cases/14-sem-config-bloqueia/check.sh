assert_no_state
assert_snaps_untouched
assert_code_untouched
[ ! -f .std/config.json ] || fail "config criado pela tuning"
assert_output "$OUT" "wbrain-std:config"
