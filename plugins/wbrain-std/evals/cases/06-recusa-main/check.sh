assert_no_state
assert_specs_untouched
assert_code_untouched
[ "$(git branch --show-current)" = main ] || fail "trocou de branch"
