#!/bin/sh
# Renovador de certificados (Let's Encrypt, HTTP-01 via webroot compartilhado com o proxy).
# Roda ao iniciar o container (todo deploy o recria) e depois, uma vez por dia, a partir de HTTPS_RENEW_DAY,
# uma vez por mês. Cada domínio é independente: a falha de um não impede os outros.
set -eu
HTTPS_DIR=/opt/https
MARKER=/etc/letsencrypt/.last-renew-month
. "$HTTPS_DIR/lib/domains.sh"
RENEW_DAY=${HTTPS_RENEW_DAY:-1}
CHECK_INTERVAL=${CHECK_INTERVAL:-3600}

renew_all() {
  staging_flag=""
  domain=""
  [ "${HTTPS_STAGING:-false}" = true ] && staging_flag=--staging
  for domain in $(https_domain_list); do
    # --keep-until-expiring: só reemite perto do vencimento, o que poupa o limite de emissões da Let's Encrypt.
    # shellcheck disable=SC2086 # staging_flag é vazio ou uma única opção
    certbot certonly --webroot -w /var/www/acme --cert-name "$domain" -d "$domain" \
      --keep-until-expiring --non-interactive --agree-tos -m "$HTTPS_EMAIL" $staging_flag \
      || echo "AVISO: falha ao emitir/renovar $domain (ver log acima); o proxy segue com o certificado atual." >&2
  done
}

renew_month_done() { [ "$(cat "$MARKER" 2>/dev/null)" = "$(date +%Y-%m)" ]; }

# Dia do mês sem zero à esquerda ("08" não é octal em sh).
day_of_month() { day=$(date +%d); echo "${day#0}"; }

renew_all
date +%Y-%m > "$MARKER"

while sleep "$CHECK_INTERVAL"; do
  if [ "$(day_of_month)" -ge "$RENEW_DAY" ] && ! renew_month_done; then
    renew_all
    date +%Y-%m > "$MARKER"
  fi
done
