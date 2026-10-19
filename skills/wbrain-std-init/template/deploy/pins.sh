#!/bin/bash
# Roda NA EC2, como root (enviado por deploy.sh pins via SSM). Só lê: não instala nem altera nada.
# Imprime os pins atuais no formato da seção host: do config.yaml, para copiar os valores.
set -euo pipefail

# Versão do pacote, no mesmo formato aceito por host.docker_version (apt pin).
docker_pkg=$(dpkg-query -W -f='${Version}' docker-ce 2>/dev/null || true)
echo "docker_version: \"$docker_pkg\""

awscli_version=$(aws --version 2>/dev/null | awk '{ sub("aws-cli/", "", $1); print $1 }' || true)
echo "awscli_version: \"$awscli_version\""
echo "awscli_sha256: \"\"  # não se recupera da instalação: baixe o zip dessa versão e rode sha256sum"

# Fingerprint da host key que o setup verificou e gravou em known_hosts (não é uma nova consulta à rede).
git_fpr=$(ssh-keygen -lf /root/.ssh/known_hosts 2>/dev/null | awk '/\(ED25519\)/ { print $2; exit }' || true)
echo "git_host_fingerprint: \"${git_fpr:-}\""

echo "--- referência (não vai para o config) ---"
echo "docker compose: $(docker compose version --short 2>/dev/null || echo ausente)"
echo "docker server:  $(docker version --format '{{.Server.Version}}' 2>/dev/null || echo ausente)"
