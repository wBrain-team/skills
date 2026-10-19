#!/bin/sh
# Entrypoint do proxy HTTPS (nginx:alpine). Gera a config, garante certificados temporários e recarrega o nginx
# sozinho quando a config ou algum certificado muda (renovação feita pelo cert-renewer). Sem restart de container.
set -eu
HTTPS_DIR=/opt/https
LE_DIR=/etc/letsencrypt
BOOTSTRAP_DIR=/etc/nginx/bootstrap
CONF=/etc/nginx/nginx.conf
WATCH_INTERVAL=${WATCH_INTERVAL:-60}
. "$HTTPS_DIR/lib/domains.sh"

# Certificado temporário por domínio sem certificado da Let's Encrypt: o nginx sobe e atende o desafio ACME.
ensure_bootstrap_certs() {
  for domain in $(https_domain_list); do
    [ -f "$LE_DIR/live/$domain/fullchain.pem" ] && continue
    [ -f "$BOOTSTRAP_DIR/$domain/fullchain.pem" ] && continue
    mkdir -p "$BOOTSTRAP_DIR/$domain"
    openssl req -x509 -nodes -newkey rsa:2048 -days 1 -subj "/CN=$domain" \
      -keyout "$BOOTSTRAP_DIR/$domain/privkey.pem" -out "$BOOTSTRAP_DIR/$domain/fullchain.pem" 2>/dev/null
    echo "https-proxy: certificado temporário para $domain (ainda sem certificado da Let's Encrypt)."
  done
}

# Impressão digital do estado servido: config + conteúdo de cada certificado em uso.
fingerprint() {
  { cat "$CONF"; for domain in $(https_domain_list); do
      cat "$LE_DIR/live/$domain/fullchain.pem" 2>/dev/null || cat "$BOOTSTRAP_DIR/$domain/fullchain.pem"
    done; } | sha256sum
}

render_config() {
  sh "$HTTPS_DIR/proxy/render-conf.sh" > "$CONF.new"
  mv "$CONF.new" "$CONF"
}

watch_certificates() {
  last=$(fingerprint)
  while sleep "$WATCH_INTERVAL"; do
    render_config || { echo "https-proxy: falha ao gerar a config; mantendo a anterior." >&2; continue; }
    current=$(fingerprint)
    [ "$current" = "$last" ] && continue
    if nginx -t 2>/dev/null; then
      nginx -s reload && echo "https-proxy: config/certificado atualizado, nginx recarregado."
      last=$current
    else
      echo "https-proxy: config nova inválida; nginx não recarregado." >&2
    fi
  done
}

command -v openssl >/dev/null || apk add --no-cache openssl >/dev/null
ensure_bootstrap_certs
render_config
watch_certificates &
exec nginx -g 'daemon off;'
