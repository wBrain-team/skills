git diff --quiet HEAD -- src-frontend docs || fail "arquivos alterados antes da aprovação"
[ -z "$(git ls-files --others --exclude-standard src-frontend docs specs)" ] || fail "arquivos criados antes da aprovação"
assert_specs_untouched
assert_output "$OUT" "dire(c|ç)(a|ã)o|dire(c|ç)(o|õ)es"
