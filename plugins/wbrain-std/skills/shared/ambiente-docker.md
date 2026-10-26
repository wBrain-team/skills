# Ambiente Docker de desenvolvimento

Regra comum às skills que gravam código (`design-system`, `tuning`, `loop`). O fluxo STD exige que desenvolvimento e testes rodem em containers (`docs/guidelines/agent-behavior.md`: nunca instalar dependências na máquina local). A `init` só cria a documentação, então o ambiente pode não existir quando a skill começa: quem precisa dele primeiro o monta.

## 1. Verificação

Com um subagente `Explore` (retorno enxuto, ver `subagentes.md`), confira **só o que a skill vai usar**:

- `docker-compose.yml` válido (`docker compose config -q`) com os serviços necessários e `healthcheck`. `design-system`: `frontend` e `nginx` (porta do showcase). `tuning`/`loop`: o que o pedido toca (backend, `db`, `db-test`, frontend).
- `Dockerfile` de cada serviço, `.env.example` e `.gitignore` cobrindo `.env` e `docker-compose.override.yml`.
- `Makefile` com os alvos que a skill chama, conforme `docs/stack/makefile.md` (`install`, `start`, `stop`, `test`, `lint`, `shell-front`, `shadcn`...).
- Frontend: volumes de `node_modules` conforme a seção 3.
- Se tudo existe, confira que sobe: `make start` (ou o equivalente do `AGENTS.md`) e os healthchecks respondem.

Tudo certo → siga a skill. Registre em uma linha o que foi conferido.

## 2. Ambiente ausente ou incompleto: propor montar

Não grave nada ainda. Mostre no chat o que falta. Em `tuning` e `loop`, montar o ambiente vira a **primeira tarefa do plano**, aprovada junto com ele (as opções abaixo aparecem no resumo do plano). Na `design-system`, proponha com `AskUserQuestion`:

- **Montar o ambiente agora (Recomendado):** escopo **mínimo** que a skill precisa, seguindo `docs/stack/infrastructure.md`, `folder-structure.md` e `makefile.md` (nginx como entrada única, arch-neutro, sem `platform:`). Liste os arquivos que serão criados ou alterados e peça o ok.
- **Usar a `wbrain-std:onboard`:** quando o projeto já existe com código e roda fora do Docker (a onboard cuida da migração, com `docker-migration.md`).
- **Seguir sem o ambiente:** só vale para as etapas em que a skill não grava nem executa nada (entrevista e proposta). Antes de gravar código, o ambiente volta a ser exigido.

Com o ok: crie só o escopo aprovado, suba, valide (healthchecks e um comando real, ex.: `make lint` ou o teste pontual) e atualize `docs/stack/infrastructure.md` e `makefile.md` com o que ficou valendo. Dependência externa que não dá para subir em container (SaaS, credencial) vira pendência para o tutor, não invenção. Mostre o resultado antes de a skill seguir. Sugira o ambiente como **commit separado** (`chore/`), antes do trabalho da skill.

A criação do ambiente é a **única** mudança de infraestrutura que essas skills fazem; não altere deploy (`deploy/`) nem o ambiente de produção.

## 3. `node_modules` em volume

`node_modules` **não fica exposto no host**: vive em volumes nomeados do Docker. Ganhos: bind mounts com milhares de arquivos são lentos em Docker Desktop; binários nativos (esbuild, rollup, lightningcss, oxide do Tailwind v4) instalados no host (ex.: macOS) quebram no container Linux; e o host continua sem dependências instaladas.

No monorepo (`workspaces: ["packages/*", "apps/*"]`) há um volume **na raiz e um por workspace**:

```yaml
services:
  frontend:
    volumes:
      - ./src-frontend:/app
      - frontend_node_modules:/app/node_modules
      - frontend_ui_node_modules:/app/packages/ui/node_modules
      - frontend_web_node_modules:/app/apps/web/node_modules
      - frontend_ds_node_modules:/app/apps/design-system/node_modules

volumes:
  frontend_node_modules:
  frontend_ui_node_modules:
  frontend_web_node_modules:
  frontend_ds_node_modules:
```

Regras:
- **Workspace novo → volume novo** no mesmo commit que o cria.
- **Instalação só no container:** `make install` roda `npm ci` dentro do serviço (`docker compose run --rm frontend npm ci`), depois de buildar a imagem. Mudou `package.json` ou o lockfile → rode de novo; o volume não se atualiza sozinho.
- **Permissões:** o dono dos volumes tem de ser o usuário do container (crie os diretórios com `chown` no `Dockerfile` ou use o usuário `node`).
- **`make clean`** remove os volumes (`docker compose down -v`); depois dele é preciso rodar `make install`.
- Os pontos de montagem aparecem como pastas `node_modules/` **vazias** no host: é esperado, e o `.gitignore` as cobre. O agente edita os arquivos no host e roda tudo (lint, build, testes, `npm`) pelo container. Sem `node_modules` no host, o editor perde autocomplete; isso é aceito.
