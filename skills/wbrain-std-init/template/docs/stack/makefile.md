# Makefile — comandos padrão

[← Stack](stack.md)

| Comando | Descrição |
|---|---|
| `make install` | Builda as imagens Docker |
| `make start` / `make stop` | Sobe / para todos os containers |
| `make restart` | Reinicia a stack do zero (build + up + healthcheck em `/health`) |
| `make test` | Executa testes do backend e frontend |
| `make test-back` | Testes do backend (unit + api) |
| `make test-unit` / `make test-api` | Apenas testes unitários / de API do backend |
| `make test-front` | Apenas testes do frontend |
| `make test-migration` | Valida o ciclo de migrations (upgrade + downgrade + re-upgrade) no banco de teste |
| `make test-coverage` | Relatório de cobertura do backend (HTML + terminal) |
| `make lint` / `make format` | Linters (Ruff + ESLint) / formatação (Ruff format + Prettier) |
| `make migrate` | Executa migrações pendentes (Alembic) |
| `make migration name=<short_description>` | Cria nova migration |
| `make charge` | Popula o banco de **dev** com dados fake — ver [Seed](../backend/seed.md) |
| `make logs` | Exibe logs dos containers |
| `make shell-back` / `make shell-front` | Shell no container do backend / frontend |
| `make shadcn component=<nome>` | Adiciona componente Shadcn |
| `make clean` | Remove containers, volumes e imagens |

**Operações dev-only** (ex.: `make charge`) só executam com `APP_ENV=development` (igualdade exata) e nunca rodam automaticamente.

---

**Veja também:** [Infraestrutura](infrastructure.md)
