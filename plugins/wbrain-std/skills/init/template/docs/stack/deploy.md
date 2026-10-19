# Deploy

[← Stack](stack.md)

O projeto nasce com um fluxo de deploy semi-automatizado em `deploy/`: uma instância EC2 por ambiente, provisionada com Terraform e operada via SSM Session Manager (sem SSH, sem porta de entrada). O deploy faz `git pull` na instância e sobe a stack com `docker compose`.

Tudo é operado por um único comando, `./deploy/deploy.sh` (menu interativo ou ação direta).

## O que é criado na AWS

| Recurso | Papel | No `down` |
|---|---|---|
| EC2 Ubuntu 24.04 | Roda a stack (Docker + Compose) | destruída |
| Volume EBS em `/ext-vol` | Código e dados persistentes | **preservado** |
| Elastic IP | IP público fixo (o DNS aponta para ele) | **preservado** (cobrado enquanto ocioso) |
| Secret `<name>-<environment>[-suffix]-env` | Conteúdo integral do `.env` de produção | **preservado** |
| Snapshots diários (DLM) | Backup do volume de dados | **preservados** (nem o `purge` apaga) |
| Security group | Sem entrada; 80/443 só com HTTPS ligado | destruído |
| Log group `/<prefixo>/ssm` | Saída completa dos comandos do `deploy.sh` | destruído |
| Alarme de status check | Falha de hardware/SO da instância | destruído |

Remover de vez o que é preservado exige o `purge`, com duas confirmações.

## Pré-requisitos do operador

- `terraform` ≥ 1.10, `aws` CLI v2, `session-manager-plugin` e `jq`.
- Credenciais AWS (env vars ou `~/.aws`). Para operar a instância, o IAM precisa de `ssm:SendCommand`, `ssm:GetCommandInvocation`, `ssm:StartSession`, `ssm:TerminateSession`, `ssm:DescribeInstanceInformation` e `logs:GetLogEvents`. Quem tem `ssm:SendCommand` ou `ssm:StartSession` na instância tem root nela: restrinja por tag/instância.
- Bucket S3 do state do Terraform, **já existente**, com versionamento e criptografia.

## Primeiro deploy

1. `cp deploy/config/config.yaml.example deploy/config/config.yaml` e preencha (`config.yaml` não é versionado). Ajustes opcionais de infra: `deploy/config/terraform.tfvars` a partir do `.example`.
2. `./deploy/deploy.sh up`: mostra o plan e cria a infra.
3. Preencha o secret de environments (console ou `aws secretsmanager put-secret-value`) com o conteúdo do `.env` de produção. O deploy recusa secret vazio.
4. `./deploy/deploy.sh setup`: instala Docker, Compose, AWS CLI e gera a deploy key. Cadastre a chave pública impressa como **Deploy Key somente leitura** no repositório.
5. `./deploy/deploy.sh deploy`: clona/atualiza, grava o `.env`, sobe a stack e valida o `health_url`.

Deploys seguintes: só o passo 5. `deploy --ref <branch|tag|sha>` implanta outra ref; sem ela, a ponta de `deploy.branch`.

## Contrato com o projeto

O que o repositório precisa fornecer está em [deploy/CONTRACT.md](../../deploy/CONTRACT.md). Em resumo: `docker-compose.yml` + `docker-compose.prod.yml` na raiz, `healthcheck` nos serviços, `.env.example` com as chaves, um serviço de entrada (nginx) e dados persistentes sob `/ext-vol/`. As migrations rodam no boot do backend.

No `.env` (o secret), `$` é interpolado pelo compose: escreva `$$` para um `$` literal.

## HTTPS público (opcional)

Com `https.enabled: true` no `config.yaml`, o deploy sobe um nginx na frente do serviço de entrada, com certificados Let's Encrypt (HTTP-01) para cada domínio de `https.domains`. Antes, aponte o DNS de cada domínio para o `elastic_ip` (output do `up`). Detalhes em [deploy/https/README.md](../../deploy/https/README.md).

## Rollback

- Manual: `deploy --ref <sha anterior>` (o SHA aparece na saída de cada deploy).
- Automático: `deploy.auto_rollback: true` volta ao SHA anterior se a subida ou o health check falhar.
- Migrations de schema **não** são revertidas em nenhum dos dois: escreva migrations compatíveis com a versão anterior do código.

## Logs e diagnóstico

- Saída de cada comando: ao vivo no terminal e completa no CloudWatch (`/<prefixo>/ssm`).
- Na instância (`./deploy/deploy.sh shell`): `/var/log/<name>-deploy.log` e `/var/log/<name>-setup.log`.
- `./deploy/deploy.sh check` mostra drift entre o Terraform e a infra real.

## Testes do deploy

```bash
bash deploy/tests/config-test.sh   # validador do config.yaml
sh deploy/tests/https-test.sh      # gerador da config do proxy HTTPS
```

## Limites conhecidos

- Uma instância por ambiente, sem alta disponibilidade. O build roda na própria instância e o proxy é recriado a cada deploy (indisponibilidade curta).
- A AZ é fixa (padrão `<região>a`): mudá-la depois exige mover o volume por snapshot.
- Imagens do HTTPS (`nginx:alpine`, `certbot/certbot`) não têm versão fixa.
- `deploy.repo` precisa estar no formato `usuario@host:caminho` (sem `ssh://` nem porta).

---

**Veja também:** [Infraestrutura](infrastructure.md) · [Estrutura de pastas](folder-structure.md)
