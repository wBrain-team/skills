# Contrato do projeto com o deploy

Este arquivo lista o que o projeto precisa fornecer para ser implantado por `deploy/`. O deploy é agnóstico
ao projeto: tudo que é específico (nomes de arquivo, caminhos, porta, health) vem de
[config/config.yaml](config/config.yaml.example), seção `app:`. O que está abaixo não é configurável e precisa
existir no repositório da branch implantada.

## Obrigatório

| Item | Detalhe |
|---|---|
| Arquivos compose | Os listados em `app.compose_files` (padrão: `docker-compose.yml` e `docker-compose.prod.yml`), na raiz do repositório. |
| Docker Compose | Versão **2.24 ou superior** (os overrides usam `!reset` e `!override`). A instância instala a versão atual do plugin. |
| Healthchecks | Os serviços que devem subir saudáveis precisam de `healthcheck`: a ação usa `up --wait`, que falha em serviço `unhealthy`. |
| Serviço de entrada | `app.proxy_service` é o serviço que recebe o tráfego (nginx). É recriado a cada deploy, depois dos demais, porque guarda o IP dos backends e lê bind mounts só na criação. Os demais serviços são recriados só quando mudam (db e redis não param à toa). |
| Health da aplicação | `app.health_url` responde `2xx` dentro de `app.health_timeout` segundos após o `up`. |
| Variáveis de ambiente | Um `.env.example` (mesmo nome do `app.env_file` + `.example`) lista as chaves necessárias. O conteúdo real vem do secret `<name>-<environment>[-suffix]-env`. |
| Dados persistentes | Bind mounts de dados ficam sob `/ext-vol/` (volume EBS da instância). `app.data_dirs` são criados antes do primeiro `up`. Dados fora de `/ext-vol/` somem quando a instância é recriada. |
| Migrations | Rodam sozinhas no boot do serviço (o deploy não executa migrations). Migrations de schema não são revertidas por rollback. |

## Opcional: HTTPS público

Com `https.enabled: true`, o projeto ainda não precisa mudar: o deploy sobe [https/](https/README.md) na frente do
`proxy_service` (que continua HTTP, na porta de `https.domains[].upstream`). Requisitos do projeto: o serviço ter porta HTTP
dentro da rede do compose e não usar as portas 80/443 do host.

## Verificado antes de subir (preflight)

Na instância, depois do checkout e da gravação do `app.env_file`, o `remote-deploy.sh` verifica:

1. Cada arquivo de `app.compose_files` existe no repositório. **Falha** o deploy.
2. A versão do Docker Compose é 2.24 ou superior. **Falha** o deploy.
3. `docker compose config` valida a combinação dos arquivos. **Falha** o deploy.
4. Chaves do `.env.example` ausentes no secret. **Só avisa**: alguns valores podem ter default no próprio compose.

## Não é contrato

- Nome do serviço do backend, do banco ou do proxy: o deploy não depende deles.
- Quantidade de serviços, redes e volumes internos ao compose.
- Linguagem e stack da aplicação: a instância só precisa de Docker e do repositório.
