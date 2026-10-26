# ADR-0006 — `node_modules` em volumes Docker

[← Decisões](decisions.md)

- **Status:** Aceito
- **Data:** 2026-10-26

## Contexto

O frontend é um monorepo (npm workspaces) e roda em container, com o código montado do
host por bind mount. Com `node_modules` no bind mount, o acesso a milhares de arquivos
é lento em Docker Desktop, e binários nativos (esbuild, rollup, lightningcss, oxide do
Tailwind v4) instalados em um sistema operacional quebram no outro.

## Decisão

`node_modules` vive em volumes nomeados do Docker, **um na raiz de `src-frontend/` e um
por workspace** (`packages/*`, `apps/*`). A instalação (`npm ci`) roda só no container,
via `make install`. O host não tem dependências instaladas.

Alternativa descartada: `node_modules` no bind mount com instalação no host (lento e com
binários incompatíveis entre host e container).

## Consequências

- Troca de dados host↔container mais rápida e sem conflito de binários.
- Workspace novo exige volume novo no compose, no mesmo commit.
- Mudança em `package.json` ou no lockfile exige `make install`; `make clean` apaga os volumes.
- Pastas `node_modules/` vazias aparecem no host (pontos de montagem), cobertas pelo `.gitignore`.
- Sem `node_modules` no host, o editor perde autocomplete; aceito, pois a edição é feita sobretudo por agentes.
- Detalhes em [Infraestrutura](../stack/infrastructure.md#node_modules-em-volumes).
