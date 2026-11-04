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

## 4. Navegador remoto (Playwright) — opcional

Camada de **testes de navegador** com `@playwright/test` (TypeScript), usada pela validação visual e pelas jornadas E2E (processo em `docs/guidelines/visual-validation.md`, detalhes em `docs/testing/visual.md`). O navegador roda num **Playwright server remoto** (container separado, fora do projeto); o projeto só tem o **cliente**. Só monte esta camada com o ok do usuário, fora da branch base e sem tocar em `deploy/`.

**Pergunte ao usuário antes de montar:**
- Existe `PW_TEST_CONNECT_WS_ENDPOINT` no ambiente? (ex.: `ws://playwright:3000/`). Sem ele, a camada não é montada e as skills declaram que a validação visual não foi possível.
- Qual a **versão do servidor** Playwright? (se não souber, descubra pela mensagem do erro 428 de uma conexão de teste, seção 4.3).
- Qual o **nome do nginx e a porta** no compose (ex.: `http://nginx:2381`)?

### 4.1 Arquitetura

- O próprio `@playwright/test` lê `PW_TEST_CONNECT_WS_ENDPOINT` (e também `PW_TEST_CONNECT_EXPOSE_NETWORK` e `PW_TEST_CONNECT_HEADERS`): **não há código de conexão a escrever**.
- `PW_TEST_CONNECT_EXPOSE_NETWORK=*` faz o navegador remoto usar a **rede do cliente** (túnel). O app é acessado por um **nome do compose** (ex.: `http://nginx:2381`), sem descobrir IP e sem depender do nome do container do desenvolvedor.
- O **cliente** é um serviço do compose em **perfil opcional** (`e2e`), com o código em `src-frontend/e2e/` (pasta própria, com `package.json` e `node_modules` em volume nomeado). Nada é instalado no host.
- Hoje cobre apps **sem backend** (showcase). Apps com login/dados exigirão fixtures de autenticação e de dados de teste: **pendência explícita**, não invente.

```yaml
services:
  e2e:
    profiles: ["e2e"]
    build: ./src-frontend
    user: root
    working_dir: /app/e2e
    depends_on:
      nginx: { condition: service_healthy }
    environment:
      PW_TEST_CONNECT_WS_ENDPOINT: ${PW_TEST_CONNECT_WS_ENDPOINT}
      PW_TEST_CONNECT_EXPOSE_NETWORK: "*"
      E2E_BASE_URL: http://nginx:2381
      E2E_TEMP: /temp
    extra_hosts:
      - "${PW_HOST}:${PW_HOST_IP}"
    volumes:
      - ./src-frontend:/app
      - ./temp:/temp
      - ./temp/flows:/app/e2e/tests/scratch
      - e2e_node_modules:/app/e2e/node_modules

volumes:
  e2e_node_modules:
```

Esqueletos do cliente (config, fixtures, specs molde, derivados de um projeto validado e **a adaptar**): `templates/e2e/` nesta pasta; copie para `src-frontend/e2e/` sem o sufixo `.example` e adapte.

No Makefile, os alvos `screenshot`, `visual`, `e2e`, `e2e-install` e `e2e-version-check` (descritos em `docs/stack/makefile.md`). `PW_HOST_IP` é calculado com `getent hosts <host-do-endpoint>` e passado por variável. Todo alvo que roda testes executa antes `make start` (que espera os healthchecks) e cria `temp/screenshot`, `temp/flows`, `temp/report` e `temp/test-results`. `temp/` fica no `.gitignore`.

### 4.2 Armadilhas (documente cada uma no projeto)

1. **Versão exata:** `@playwright/test` e o servidor precisam da **mesma versão**; senão, `428 Precondition Required` ("Playwright version mismatch ... server version vX / client version vY"). Fixe a versão exata no `package.json` (sem `^`). Servidor atualizado? Atualize a versão e rode `make e2e-install`. `make e2e-version-check` conecta e avisa a divergência.
2. **O cliente não resolve o nome do servidor Playwright** na rede do compose: use `extra_hosts` com o IP (acima). É o único nome que precisa disso.
3. **Vite bloqueia hosts desconhecidos** (HTTP 403, "Blocked request. This host is not allowed"). Com o túnel o `Host` é o nome do compose (ex.: `nginx`): acrescente-o em `server.allowedHosts` do `vite.config.ts`. Sintoma útil: o teste "conecta" e chega ao Vite, mas não acha o conteúdo.
4. **Sem o túnel** (IP ou nome do container do dev), o Chrome força HTTPS para hosts como `dev` (TLD `.dev` na lista HSTS): `net::ERR_SSL_PROTOCOL_ERROR`. Use `EXPOSE_NETWORK` e um nome do compose.
5. **Variáveis de ambiente vazias:** o Makefile repassa parâmetros como `-e SHOT_THEME=""`. Em TypeScript use `||`, não `??`, para cair no padrão.
6. **Script de init por navegação:** `addInitScript` (tema/idioma na fixture) roda em **toda** carga, inclusive `reload()`, e desfaz a escolha do usuário numa jornada. Defina o valor **só se ainda não existir** (`if (localStorage.getItem(k) === null) ...`).
7. **Bind mount de saída** (`./temp`) criado pelo Docker/Makefile como root: o usuário `node` não escreve. Como todo o ambiente é Docker, o serviço `e2e` roda com `user: root` (sem chmod nem UID). Se alguém rodar como `node`, o fallback é `chmod -R a+rwX temp` (atalho de dev: registre).
8. **`node_modules` do cliente em volume nomeado** (seção 3): pasta nova de cliente → volume novo, no mesmo commit. Se o serviço rodar como não-root, `chown` do diretório no Dockerfile (`mkdir`/`chown` de `/app/e2e/node_modules`).
9. **ESLint:** `use()` das fixtures do Playwright dispara `react-hooks/rules-of-hooks`; desligue a regra só para `e2e/**`. Configure `globals` de Node e navegador (há `page.evaluate`). Rode também `tsc --noEmit` em `e2e/`.
10. **Roteamento:** `HashRouter` (`/#/rota`) dispensa reescrita no nginx; com outro roteador, confira o fallback do nginx.
11. **Ambiente parado:** o alvo `make` roda `make start` antes dos testes.
12. **Imagens comparáveis:** `reducedMotion: "reduce"` e espera de `document.fonts.ready`.

### 4.3 Validar a conexão (antes de montar tudo)

Container descartável `node:22-alpine` na rede do compose, com `--add-host <host-do-endpoint>:<ip>`, `npm i @playwright/test@<versão>` e um spec de 5 linhas: `page.goto('/')`, `expect(heading).toBeVisible()`, `screenshot`, com `PW_TEST_CONNECT_WS_ENDPOINT` e `PW_TEST_CONNECT_EXPOSE_NETWORK='*'`. Diagnóstico por erro:

| Erro | Causa |
|---|---|
| `428` | versão do cliente ≠ servidor |
| `403` | `allowedHosts` do Vite |
| `ERR_SSL_PROTOCOL_ERROR` | host forçado a HTTPS (sem túnel) |
| falha de DNS do servidor | falta `extra_hosts` |
