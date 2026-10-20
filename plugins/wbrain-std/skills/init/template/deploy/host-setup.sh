#!/bin/bash
# Roda NA EC2, como root (enviado por deploy.sh via SSM). Idempotente: pode rodar de novo
# para atualizar. Instala git, Docker Engine e Docker Compose (plugin), AWS CLI e a deploy key.
# Versões e checksums vêm de config.yaml (seção host:) pelas variáveis DEPLOY_CFG_*.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
for var in DEPLOY_CFG_NAME DEPLOY_CFG_REPO DEPLOY_CFG_GIT_HOST_FINGERPRINT; do
  [ -n "${!var:-}" ] || { echo "Variável ausente: $var (rode pelo deploy.sh)." >&2; exit 64; }
done
# A saída do SSM é truncada: o log completo fica na instância (/var/log/<name>-setup.log, lido via shell).
exec > >(tee -a "/var/log/${DEPLOY_CFG_NAME}-setup.log") 2>&1

# Mesmo lock do remote-deploy.sh: o setup pode reiniciar o Docker e não roda junto com um deploy.
exec 9>"/var/lock/${DEPLOY_CFG_NAME}-deploy.lock"
flock -n 9 || { echo "Um deploy ou outro setup está em andamento; tente de novo depois." >&2; exit 1; }

# Chave pública do repositório Docker (https://docs.docker.com/engine/install/ubuntu/): a chave baixada
# precisa ter esta impressão digital, senão o apt confiaria num repositório trocado.
DOCKER_GPG_FPR=9DC858229FC7DD38854AE2D88D81803C0EBFCD88

apt-get update -y
apt-get install -y ca-certificates curl git unzip jq gnupg

# Docker já instalado não é atualizado: um upgrade do docker-ce reinicia o daemon e os containers em produção.
# Só instala/troca quando não há Docker ou quando docker_version (pin) é diferente da versão atual.
installed_docker=$(dpkg-query -W -f='${Version}' docker-ce 2>/dev/null || true)
if [ -z "$installed_docker" ] || { [ -n "${DEPLOY_CFG_DOCKER_VERSION:-}" ] && [ "$installed_docker" != "$DEPLOY_CFG_DOCKER_VERSION" ]; }; then
  fresh_docker=false
  [ -n "$installed_docker" ] || fresh_docker=true

  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    fpr=$(gpg --show-keys --with-colons /etc/apt/keyrings/docker.asc | awk -F: '/^fpr:/ { print $10; exit }')
    [ "$fpr" = "$DOCKER_GPG_FPR" ] || { echo "Chave GPG do Docker inesperada: $fpr" >&2; rm -f /etc/apt/keyrings/docker.asc; exit 1; }
    chmod a+r /etc/apt/keyrings/docker.asc
    # shellcheck disable=SC1091 # /etc/os-release existe na EC2 (Ubuntu), não no host de lint
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      > /etc/apt/sources.list.d/docker.list
    apt-get update -y
  fi

  # docker_version preenchido fixa docker-ce e docker-ce-cli nela; vazio = a versão atual do repositório.
  docker_pkgs=(docker-ce docker-ce-cli)
  if [ -n "${DEPLOY_CFG_DOCKER_VERSION:-}" ]; then
    docker_pkgs=("docker-ce=$DEPLOY_CFG_DOCKER_VERSION" "docker-ce-cli=$DEPLOY_CFG_DOCKER_VERSION")
  fi
  apt-get install -y "${docker_pkgs[@]}" containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker

  # Rotação dos logs dos containers. Só na instalação nova (sem containers ainda): aplicar depois exigiria
  # reiniciar o daemon. Nunca sobrescreve um daemon.json feito à mão.
  if [ "$fresh_docker" = true ] && [ ! -f /etc/docker/daemon.json ]; then
    echo '{"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"3"}}' > /etc/docker/daemon.json
    systemctl restart docker
  fi
else
  echo "Docker $installed_docker mantido (sem atualização: nenhum docker_version diferente no config)."
  systemctl enable docker
fi

# ssm-user é o usuário das sessões do Session Manager (criado na 1ª sessão; cria antes se faltar).
id ssm-user >/dev/null 2>&1 || useradd -m -s /bin/bash ssm-user
usermod -aG docker ssm-user

# O SSM Agent só concede sudo sem senha ao criar o ssm-user ele mesmo; como o criamos antes, sem esta
# regra o `sudo` das sessões pede uma senha que não existe. Valida com visudo para não quebrar o sudo.
SUDOERS_FILE=/etc/sudoers.d/ssm-agent-users
echo "ssm-user ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE.tmp"
chmod 0440 "$SUDOERS_FILE.tmp"
visudo -cf "$SUDOERS_FILE.tmp" >/dev/null
mv "$SUDOERS_FILE.tmp" "$SUDOERS_FILE"

# AWS CLI v2: o deploy lê o secret de envs com a role da instância. Com awscli_version, instala essa versão
# e exige o sha256 do zip (awscli_sha256); sem versão, instala a atual só se faltar.
awscli_current=$(aws --version 2>/dev/null | awk '{ sub("aws-cli/", "", $1); print $1 }' || true)
if [ -n "${DEPLOY_CFG_AWSCLI_VERSION:-}" ]; then
  [ -n "${DEPLOY_CFG_AWSCLI_SHA256:-}" ] || { echo "host.awscli_version exige host.awscli_sha256 no config.yaml." >&2; exit 1; }
  [ "$awscli_current" = "$DEPLOY_CFG_AWSCLI_VERSION" ] || {
    tmp=$(mktemp -d)
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m)-$DEPLOY_CFG_AWSCLI_VERSION.zip" -o "$tmp/awscliv2.zip"
    echo "$DEPLOY_CFG_AWSCLI_SHA256  $tmp/awscliv2.zip" | sha256sum -c - >/dev/null || { echo "sha256 do AWS CLI não confere." >&2; rm -rf "$tmp"; exit 1; }
    unzip -q "$tmp/awscliv2.zip" -d "$tmp"
    "$tmp/aws/install" --update
    rm -rf "$tmp"
  }
elif [ -z "$awscli_current" ]; then
  tmp=$(mktemp -d)
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "$tmp/awscliv2.zip"
  unzip -q "$tmp/awscliv2.zip" -d "$tmp"
  "$tmp/aws/install"
  rm -rf "$tmp"
fi

# Deploy key (somente leitura) para o git pull do deploy; a pública é impressa para cadastro no GitHub.
DEPLOY_KEY=/root/.ssh/${DEPLOY_CFG_NAME}_deploy
if [ ! -f "$DEPLOY_KEY" ]; then
  install -d -m 0700 /root/.ssh
  ssh-keygen -t ed25519 -N "" -C "${DEPLOY_CFG_NAME}-deploy" -f "$DEPLOY_KEY" >/dev/null
fi

# known_hosts do repositório: o host sai de deploy.repo (formato usuario@host:caminho) e a chave ed25519
# só é aceita se a impressão digital bater com host.git_host_fingerprint (publicada pelo provedor).
GIT_HOST=${DEPLOY_CFG_REPO#*@}
GIT_HOST=${GIT_HOST%%:*}
scanned=$(mktemp)
ssh-keyscan -t ed25519 "$GIT_HOST" > "$scanned" 2>/dev/null || true
fpr=$(ssh-keygen -lf "$scanned" 2>/dev/null | awk '{ print $2 }' || true)
[ -n "$fpr" ] && [ "$fpr" = "$DEPLOY_CFG_GIT_HOST_FINGERPRINT" ] || {
  echo "Host key de $GIT_HOST não confere: obtido '${fpr:-nenhum}', esperado '$DEPLOY_CFG_GIT_HOST_FINGERPRINT'." >&2
  rm -f "$scanned"
  exit 1
}
install -m 0644 "$scanned" /root/.ssh/known_hosts
rm -f "$scanned"

mountpoint -q /ext-vol || echo "AVISO: /ext-vol não está montado (volume de dados)."

echo "--- versões ---"
docker --version
docker compose version
git --version
aws --version

echo "--- deploy key pública (cadastre como Deploy Key somente leitura no repositório) ---"
cat "$DEPLOY_KEY.pub"
