# Renovador de certificados. Contexto de build: deploy/https (copia a lib de domínios e o entrypoint).
# Imagem oficial do certbot (multi-arch): o build roda na máquina de destino, sem --platform.
FROM certbot/certbot

COPY lib /opt/https/lib
COPY renewer/entrypoint.sh /opt/https/renewer/entrypoint.sh

ENTRYPOINT ["/bin/sh", "/opt/https/renewer/entrypoint.sh"]
