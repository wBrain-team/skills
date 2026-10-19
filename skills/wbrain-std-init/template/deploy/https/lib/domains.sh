# shellcheck shell=sh
# Lista de domínios do HTTPS: variável HTTPS_DOMAINS no formato `dominio=servico:porta,dominio2=servico2:porta2`.
# Compartilhado pelo proxy e pelo renovador (montado/copiado em /opt/https). Deve ser "sourced", não executado.

https_domain_list() {
  printf '%s' "${HTTPS_DOMAINS:-}" | tr ',' '\n' | cut -d= -f1 | grep -v '^$' || true
}

https_upstream_for() {
  printf '%s' "${HTTPS_DOMAINS:-}" | tr ',' '\n' | awk -F= -v domain="$1" '$1 == domain { print $2; exit }'
}
