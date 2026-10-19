# Backend

[← Índice](../docs.md)

FastAPI + SQLAlchemy 2.x (async) + PostgreSQL 17, em camadas Router → Service →
Repository → Model.

| Arquivo | Conteúdo |
|---|---|
| [layers.md](layers.md) | Responsabilidade de cada camada e checklist de revisão |
| [shared-pieces.md](shared-pieces.md) | `BaseRepository`, `get_or_404`, `paginate`, `PageMeta` e afins |
| [exceptions.md](exceptions.md) | `DomainException` e handler global |
| [api-contract.md](api-contract.md) | Envelopes de sucesso/erro e convenções de URL |
| [config.md](config.md) | `Settings` (pydantic-settings) e `.env.example` |
| [database.md](database.md) | Engine, sessão por request e `get_db` |
| [migrations.md](migrations.md) | Fluxo e regras do Alembic |
| [logging.md](logging.md) | Logging estruturado e `request_id` |
| [audit-log.md](audit-log.md) | Auditoria automática via eventos de sessão |
| [jobs.md](jobs.md) | Tarefas agendadas no container `cron` |
| [seed.md](seed.md) | `make charge` (dados fake de dev) |

---

**Veja também:** [Auth](../auth/auth.md) · [Testes](../testing/testing.md) · [Tecnologias](../stack/technologies.md)
