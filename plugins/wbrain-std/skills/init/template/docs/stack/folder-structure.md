# Estrutura de pastas

[← Stack](stack.md)

Todo diretório com código-fonte de um serviço usa o prefixo `src-` (ex.: `src-backend`, `src-frontend`), separando código de configuração de infra.

```
/
├── docs/                  # Esta documentação
├── snapshots/                 # Fonte da verdade do produto (alterações aprovadas pelo tutor)
├── src-backend/
│   ├── app/
│   │   ├── api/           # Routers FastAPI + deps.py, pagination.py
│   │   ├── core/          # Config, segurança, DB, exceptions, audit/
│   │   ├── models/        # Modelos SQLAlchemy
│   │   ├── schemas/       # Schemas Pydantic (+ common.py)
│   │   ├── services/      # Lógica de negócio (+ helpers.py)
│   │   ├── repositories/  # Acesso a dados (BaseRepository + 1 repo por entidade)
│   │   └── tests/         # ver docs/testing/
│   ├── alembic/           # Migrações
│   ├── Dockerfile
│   └── requirements.txt
├── src-frontend/          # Monorepo npm workspaces — ver docs/frontend/ (node_modules em volumes Docker)
├── nginx/nginx.conf       # Proxy reverso: :8084 app, :8085 design system
├── docker-compose.yml     # backend, frontend, nginx, cron, db, db-test
├── docker-compose.override.yml    # config local (gitignored)
├── docker-compose.prod.yml        # overrides de produção (usado pelo deploy)
├── deploy/                # Deploy na AWS: Terraform, scripts e HTTPS — ver docs/stack/deploy.md
├── Makefile
├── .env.example
├── AGENTS.md / CLAUDE.md  # Entrada para agentes de IA
└── README.md              # Visão geral e como rodar
```

Detalhes por camada: [backend](../backend/backend.md), [testes](../testing/testing.md#estrutura-de-pastas), [frontend](../frontend/structure.md).

---

**Veja também:** [Tecnologias](technologies.md) · [Deploy](deploy.md)
