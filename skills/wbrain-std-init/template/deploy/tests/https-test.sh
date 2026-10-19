#!/bin/sh
# Testes do gerador de configuração do proxy HTTPS (deploy/https/proxy/render-conf.sh) e da lista de domínios.
# Uso: sh deploy/tests/https-test.sh   (sai com código ≠ 0 se algum caso falhar)
DIR="$(cd "$(dirname "$0")" && pwd)"
HTTPS_DIR="$DIR/../https"
failures=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

check() {
  if [ "$2" = ok ]; then echo "ok    $1"; else echo "FALHA $1"; failures=$((failures + 1)); fi
}

render() {
  HTTPS_DOMAINS=$1 LE_DIR="$tmp/le" BOOTSTRAP_DIR=/etc/nginx/bootstrap sh "$HTTPS_DIR/proxy/render-conf.sh" 2>/dev/null
}

# Lista: `dominio=upstream` separados por vírgula, na ordem.
. "$HTTPS_DIR/lib/domains.sh"
domains_out=$(HTTPS_DOMAINS='a.example.com=nginx:8084,b.example.com=svc:9000' https_domain_list)
[ "$domains_out" = "a.example.com
b.example.com" ] && check "lista emite um domínio por linha" ok || check "lista emite um domínio por linha" fail
upstream_out=$(HTTPS_DOMAINS='a.example.com=nginx:8084,b.example.com=svc:9000' https_upstream_for b.example.com)
[ "$upstream_out" = "svc:9000" ] && check "upstream por domínio" ok || check "upstream por domínio" fail

# Um server 443 por domínio, cada um com o próprio proxy_pass.
conf=$(render 'a.example.com=nginx:8084,b.example.com=svc:9000')
echo "$conf" | grep -q 'server_name a.example.com;' && check "gera server_name do primeiro domínio" ok || check "gera server_name do primeiro domínio" fail
echo "$conf" | grep -q 'server_name b.example.com;' && check "gera server_name do segundo domínio" ok || check "gera server_name do segundo domínio" fail
echo "$conf" | grep -q 'set \$upstream http://nginx:8084;' && check "upstream do primeiro domínio" ok || check "upstream do primeiro domínio" fail
echo "$conf" | grep -q 'set \$upstream http://svc:9000;' && check "upstream do segundo domínio (outra porta/serviço)" ok || check "upstream do segundo domínio (outra porta/serviço)" fail
[ "$(echo "$conf" | grep -c 'listen 443 ssl;')" -eq 2 ] && check "dois server 443 (um por domínio)" ok || check "dois server 443 (um por domínio)" fail

# Desafio HTTP-01 e redirect para https na porta 80.
echo "$conf" | grep -q 'location /.well-known/acme-challenge/' && check "porta 80 atende o desafio ACME" ok || check "porta 80 atende o desafio ACME" fail
echo "$conf" | grep -q 'return 301 https://\$host\$request_uri;' && check "porta 80 redireciona para https" ok || check "porta 80 redireciona para https" fail

# WebSocket: o upgrade do cliente precisa atravessar o proxy TLS.
echo "$conf" | grep -q 'proxy_set_header Upgrade \$http_upgrade;' && check "repassa header Upgrade" ok || check "repassa header Upgrade" fail
echo "$conf" | grep -q 'proxy_set_header Connection \$connection_upgrade;' && check "repassa header Connection" ok || check "repassa header Connection" fail

# Certificado: usa o da Let's Encrypt quando existe; senão o temporário (bootstrap).
mkdir -p "$tmp/le/live/a.example.com"
touch "$tmp/le/live/a.example.com/fullchain.pem" "$tmp/le/live/a.example.com/privkey.pem"
conf=$(render 'a.example.com=nginx:8084,b.example.com=svc:9000')
echo "$conf" | grep -q "ssl_certificate $tmp/le/live/a.example.com/fullchain.pem;" \
  && check "usa certificado live quando existe" ok || check "usa certificado live quando existe" fail
echo "$conf" | grep -q 'ssl_certificate /etc/nginx/bootstrap/b.example.com/fullchain.pem;' \
  && check "usa certificado temporário quando não há live" ok || check "usa certificado temporário quando não há live" fail

# Domínio inválido na lista aborta a geração (nada de config quebrada no nginx).
if render 'bad_domain!=nginx:8084' >/dev/null; then check "recusa lista inválida" fail; else check "recusa lista inválida" ok; fi

echo
if [ "$failures" -eq 0 ]; then echo "Todos os casos passaram."; else echo "$failures caso(s) falharam."; fi
exit "$failures"
