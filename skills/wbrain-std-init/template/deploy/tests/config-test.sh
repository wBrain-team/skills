#!/bin/bash
# Testes do validador de config.yaml (config_validate em infra/infra-lib.sh).
# Uso: bash deploy/tests/config-test.sh   (sai com código ≠ 0 se algum caso falhar)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../infra/infra-lib.sh"
set +e

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failures=0

expect_valid() {
  local name=$1 file=$2
  if config_validate "$file" 2>/dev/null; then echo "ok    $name"; else echo "FALHA $name (deveria aceitar)"; failures=$((failures + 1)); fi
}

expect_invalid() {
  local name=$1 file=$2
  if config_validate "$file" 2>/dev/null; then echo "FALHA $name (deveria recusar)"; failures=$((failures + 1)); else echo "ok    $name"; fi
}

expect_valid "exemplo do repositório é válido" "$DIR/../config/config.yaml.example"

printf 'name: your-project\nstate:\n\tbucket: x\n' > "$tmp/tab.yaml"
expect_invalid "recusa tab na indentação" "$tmp/tab.yaml"

printf 'name: your-project\nstate:\n    bucket: x\n' > "$tmp/indent4.yaml"
expect_invalid "recusa indentação de 4 espaços" "$tmp/indent4.yaml"

printf 'name: your-project\nname: outro\n' > "$tmp/dup.yaml"
expect_invalid "recusa chave duplicada no topo" "$tmp/dup.yaml"

printf 'state:\n  bucket: a\n  bucket: b\n' > "$tmp/dup_section.yaml"
expect_invalid "recusa chave duplicada numa seção" "$tmp/dup_section.yaml"

printf 'name your-project\n' > "$tmp/no_colon.yaml"
expect_invalid "recusa linha sem dois-pontos" "$tmp/no_colon.yaml"

printf '# comentário\n\nname: "your-project" # inline\nstate:\n  bucket: "b"\n' > "$tmp/quoted.yaml"
expect_valid "aceita aspas e comentário inline" "$tmp/quoted.yaml"

printf 'https:\n  enabled: true\n  domains:\n    - domain: a.example.com\n      upstream: nginx:8084\n    - domain: b.example.com\n      upstream: svc:9000\n' > "$tmp/list.yaml"
expect_valid "aceita lista de objetos sob seção" "$tmp/list.yaml"

printf 'https:\n  domains:\n      domain: a.example.com\n' > "$tmp/list_no_dash.yaml"
expect_invalid "recusa continuação de item sem traço" "$tmp/list_no_dash.yaml"

printf 'https:\n  domains:\n    - domain: a.example.com\n      domain: b.example.com\n' > "$tmp/list_dup_item.yaml"
expect_invalid "recusa chave duplicada dentro do item" "$tmp/list_dup_item.yaml"

printf 'domains:\n    - domain: a.example.com\n' > "$tmp/list_top.yaml"
expect_invalid "recusa lista fora de seção" "$tmp/list_top.yaml"

printf 'https:\n  domains:\n    - domain: a.example.com\n     upstream: nginx:8084\n' > "$tmp/list_bad_indent.yaml"
expect_invalid "recusa indentação errada no item" "$tmp/list_bad_indent.yaml"

list_out=$(config_list "$tmp/list.yaml" https domains)
if [ "$list_out" = $'a.example.com|nginx:8084\nb.example.com|svc:9000' ]; then echo "ok    config_list emite um item por linha"; else echo "FALHA config_list (saída: $list_out)"; failures=$((failures + 1)); fi

# Validação semântica do bloco https (só quando enabled: true)
expect_https_ok() {
  local name=$1 file=$2
  if CONFIG_FILE=$file config_https_check 2>/dev/null; then echo "ok    $name"; else echo "FALHA $name (deveria aceitar)"; failures=$((failures + 1)); fi
}
expect_https_invalid() {
  local name=$1 file=$2
  if CONFIG_FILE=$file config_https_check 2>/dev/null; then echo "FALHA $name (deveria recusar)"; failures=$((failures + 1)); else echo "ok    $name"; fi
}

printf 'https:\n  enabled: false\n' > "$tmp/https_off.yaml"
expect_https_ok "https desabilitado não exige nada" "$tmp/https_off.yaml"

printf 'https:\n  enabled: true\n  domains:\n    - domain: a.example.com\n      upstream: nginx:8084\n' > "$tmp/https_no_email.yaml"
expect_https_invalid "https habilitado exige email" "$tmp/https_no_email.yaml"

printf 'https:\n  enabled: true\n  email: ops@example.com\n' > "$tmp/https_no_domains.yaml"
expect_https_invalid "https habilitado exige ao menos um domínio" "$tmp/https_no_domains.yaml"

printf 'https:\n  enabled: true\n  email: ops@example.com\n  domains:\n    - domain: bad_domain!\n      upstream: nginx:8084\n' > "$tmp/https_bad_domain.yaml"
expect_https_invalid "recusa domínio inválido" "$tmp/https_bad_domain.yaml"

printf 'https:\n  enabled: true\n  email: ops@example.com\n  domains:\n    - domain: a.example.com\n      upstream: nginx:70000\n' > "$tmp/https_bad_port.yaml"
expect_https_invalid "recusa porta fora de 1-65535" "$tmp/https_bad_port.yaml"

printf 'https:\n  enabled: true\n  email: ops@example.com\n  domains:\n    - domain: a.example.com\n      upstream: nginx:8084\n    - domain: a.example.com\n      upstream: svc:9000\n' > "$tmp/https_dup.yaml"
expect_https_invalid "recusa domínio duplicado" "$tmp/https_dup.yaml"

printf 'https:\n  enabled: true\n  email: ops@example.com\n  renew_day: 29\n  domains:\n    - domain: a.example.com\n      upstream: nginx:8084\n' > "$tmp/https_renew.yaml"
expect_https_invalid "recusa renew_day fora de 1-28" "$tmp/https_renew.yaml"

printf 'https:\n  enabled: true\n  email: ops@example.com\n  domains:\n    - domain: a.example.com\n      upstream: nginx:8084\n    - domain: b.example.com\n      upstream: other-svc:9000\n' > "$tmp/https_ok.yaml"
expect_https_ok "https habilitado válido com dois domínios" "$tmp/https_ok.yaml"

# Validação de name/environment/suffix (nomes AWS e caminhos na instância)
expect_names_ok() {
  local name=$1 file=$2
  if CONFIG_FILE=$file config_names_check 2>/dev/null; then echo "ok    $name"; else echo "FALHA $name (deveria aceitar)"; failures=$((failures + 1)); fi
}
expect_names_invalid() {
  local name=$1 file=$2
  if CONFIG_FILE=$file config_names_check 2>/dev/null; then echo "FALHA $name (deveria recusar)"; failures=$((failures + 1)); else echo "ok    $name"; fi
}

expect_names_ok "nomes do exemplo do repositório" "$DIR/../config/config.yaml.example"

printf 'name: my-app\nenvironment: prod\nsuffix: cliente-a\n' > "$tmp/names_ok.yaml"
expect_names_ok "aceita name, environment e suffix válidos" "$tmp/names_ok.yaml"

printf 'name: My_App\nenvironment: prod\n' > "$tmp/names_upper.yaml"
expect_names_invalid "recusa maiúscula e sublinhado no name" "$tmp/names_upper.yaml"

printf 'name: app\nenvironment: ../prod\n' > "$tmp/names_path.yaml"
expect_names_invalid "recusa caminho no environment" "$tmp/names_path.yaml"

printf 'name: app\nenvironment: prod\nsuffix: -a\n' > "$tmp/names_dash.yaml"
expect_names_invalid "recusa hífen na ponta do suffix" "$tmp/names_dash.yaml"

printf 'name: %s\nenvironment: prod\n' "$(printf 'a%.0s' $(seq 1 60))" > "$tmp/names_long.yaml"
expect_names_invalid "recusa prefixo com mais de 60 caracteres" "$tmp/names_long.yaml"

echo
if [ "$failures" -eq 0 ]; then echo "Todos os casos passaram."; else echo "$failures caso(s) falharam."; fi
exit "$failures"
