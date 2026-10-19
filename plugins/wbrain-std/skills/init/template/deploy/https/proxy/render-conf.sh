#!/bin/sh
# Gera o nginx.conf do proxy HTTPS (stdout): um server 443 por domínio, cada um com o seu upstream.
# Entradas: HTTPS_DOMAINS (ver lib/domains.sh), LE_DIR (certificados da Let's Encrypt) e BOOTSTRAP_DIR (temporários).
# Usa o certificado da Let's Encrypt quando existe; senão o temporário, para o nginx subir antes da primeira emissão.
set -eu
LIB_DIR="$(cd "$(dirname "$0")/../lib" && pwd)"
. "$LIB_DIR/domains.sh"
LE_DIR=${LE_DIR:-/etc/letsencrypt}
BOOTSTRAP_DIR=${BOOTSTRAP_DIR:-/etc/nginx/bootstrap}
DOMAIN_RE='^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$'
UPSTREAM_RE='^[A-Za-z0-9._-]+:[0-9]+$'

DOMAINS_LIST=$(https_domain_list)
[ -n "$DOMAINS_LIST" ] || { echo "render-conf: HTTPS_DOMAINS vazio." >&2; exit 1; }

# Valida tudo antes de imprimir qualquer linha: config pela metade não chega ao nginx.
for domain in $DOMAINS_LIST; do
  printf '%s\n' "$domain" | grep -Eq "$DOMAIN_RE" || { echo "render-conf: domínio inválido: $domain" >&2; exit 1; }
  upstream=$(https_upstream_for "$domain")
  printf '%s\n' "$upstream" | grep -Eq "$UPSTREAM_RE" || { echo "render-conf: destino inválido para $domain: '$upstream' (use servico:porta)" >&2; exit 1; }
  port=${upstream##*:}
  { [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; } || { echo "render-conf: porta fora de 1-65535 para $domain: $port" >&2; exit 1; }
done

cat <<EOF
worker_processes auto;
events { worker_connections 1024; }
http {
  include /etc/nginx/mime.types;
  sendfile on;
  client_max_body_size 128m;
  # DNS do Docker: o upstream é resolvido por requisição, então um serviço recriado não derruba o proxy.
  resolver 127.0.0.11 valid=5s;
  # WebSocket: repassa o upgrade do cliente; sem ele o handshake morre aqui, no TLS.
  map \$http_upgrade \$connection_upgrade { default upgrade; '' close; }

  server {
    listen 80;
    server_name _;
    location /.well-known/acme-challenge/ { root /var/www/acme; }
    location / { return 301 https://\$host\$request_uri; }
  }
EOF

for domain in $DOMAINS_LIST; do
  upstream=$(https_upstream_for "$domain")
  if [ -f "$LE_DIR/live/$domain/fullchain.pem" ] && [ -f "$LE_DIR/live/$domain/privkey.pem" ]; then
    cert="$LE_DIR/live/$domain/fullchain.pem"; key="$LE_DIR/live/$domain/privkey.pem"
  else
    cert="$BOOTSTRAP_DIR/$domain/fullchain.pem"; key="$BOOTSTRAP_DIR/$domain/privkey.pem"
  fi
  cat <<EOF

  server {
    listen 443 ssl;
    server_name $domain;
    ssl_certificate $cert;
    ssl_certificate_key $key;
    ssl_protocols TLSv1.2 TLSv1.3;
    location / {
      set \$upstream http://$upstream;
      proxy_pass \$upstream;
      proxy_http_version 1.1;
      proxy_set_header Host \$host;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection \$connection_upgrade;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto \$scheme;
      # SSE e respostas em streaming: sem buffer e com timeout longo, como no nginx do projeto.
      proxy_buffering off;
      proxy_read_timeout 300s;
      proxy_send_timeout 300s;
    }
  }
EOF
done

echo "}"
