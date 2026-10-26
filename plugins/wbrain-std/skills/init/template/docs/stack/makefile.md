# Makefile — comandos padrão

[← Stack](stack.md)

| Comando | Descrição |
|---|---|
| `make install` | Builda as imagens Docker e instala as dependências do frontend (`npm ci`) nos volumes de `node_modules` |
| `make start` / `make stop` | Sobe / para todos os containers |
| `make restart` | Reinicia a stack do zero (build + up + healthcheck em `/health`) |
| `make test` | Executa testes do backend e frontend |
| `make test-back` | Testes do backend (unit + api) |
| `make test-unit` / `make test-api` | Apenas testes unitários / de API do backend |
| `make test-front` | Apenas testes do frontend |
| `make test-migration` | Valida o ciclo de migrations (upgrade + downgrade + re-upgrade) no banco de teste |
| `make test-coverage` | Cobertura do backend (pytest-cov, HTML + terminal); falha abaixo de 80% de linhas ou branches em `app/services/` |
| `make test-coverage-front` | Cobertura do frontend (Vitest, provider v8); falha abaixo de 80% de linhas ou branches |
| `make lint` / `make format` | Linters (Ruff + ESLint) / formatação (Ruff format + Prettier) |
| `make migrate` | Executa migrações pendentes (Alembic) |
| `make migration name=<short_description>` | Cria nova migration |
| `make charge` | Popula o banco de **dev** com dados fake — ver [Seed](../backend/seed.md) |
| `make logs` | Exibe logs dos containers |
| `make shell-back` / `make shell-front` | Shell no container do backend / frontend |
| `make shadcn component=<nome>` | Adiciona componente Shadcn |
| `make clean` | Remove containers, volumes (inclusive `node_modules`) e imagens; rode `make install` depois |

**Operações dev-only** (ex.: `make charge`) só executam com `APP_ENV=development` (igualdade exata) e nunca rodam automaticamente.

---

**Veja também:** [Infraestrutura](infrastructure.md)
