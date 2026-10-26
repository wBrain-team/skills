[ -z "$(git status --porcelain)" ] || fail "arquivos alterados num projeto sem frontend"
assert_output "$OUT" "frontend"
