# Testes

[← Índice](../docs.md)

O desenvolvimento segue TDD estrito (ver [TDD](../guidelines/tdd.md)).

| Arquivo | Conteúdo |
|---|---|
| [backend-unit.md](backend-unit.md) | Testes unitários de services, com mocks |
| [backend-api.md](backend-api.md) | Testes de endpoint: princípios e exemplos |
| [test-database.md](test-database.md) | Container `db-test`, isolamento por rollback, `conftest.py`, execução paralela |
| [fixtures-factories.md](fixtures-factories.md) | `factory_boy`, `bind_factories`, `auth_headers` |
| [frontend.md](frontend.md) | Vitest + React Testing Library |

## Tipos de teste e responsabilidades

| Tipo | O que testa | Ferramentas |
|---|---|---|
| **Unitário (backend)** | Funções, services e lógica de negócio isolados | Pytest + unittest.mock |
| **Unitário (frontend)** | Componentes, hooks e funções utilitárias | Vitest + React Testing Library |
| **API (integração)** | Endpoints HTTP de ponta a ponta | Pytest + httpx (AsyncClient) |

**Ordem de escrita:**
1. Testes unitários — valide a lógica isolada primeiro.
2. Testes de API — valide o contrato HTTP depois que a lógica estiver coberta.

Nunca implemente um endpoint ou service sem cobertura de testes.

## Rastreabilidade snapshot → teste

Todo teste de regra de negócio traz um comentário com o caminho do snapshot que ele garante: `# snapshot: snapshots/pedidos/regras.md` (Python) ou `// snapshot: snapshots/pedidos/lista.md` (TS). No topo do arquivo, vale para todos os testes dele; um teste pode ter mais de um marcador. Testes técnicos (infraestrutura, fumaça) ficam sem marcador. Snapshot removida leva junto os testes marcados com ela.

## Estrutura de pastas

```
src-backend/app/tests/
├── conftest.py          # Fixtures globais (engine, db_session, client, bind_factories, committing_db_session)
├── factories.py         # Factories (factory_boy) para seed de dados
├── helpers.py           # auth_headers / admin_headers (token JWT real)
├── unit/                # Testes unitários (sem banco, com mocks)
│   ├── test_user_service.py
│   └── test_auth_service.py
└── api/                 # Testes de endpoint (banco PostgreSQL de teste real)
    ├── test_users_router.py
    └── test_auth_router.py

src-frontend/apps/web/src/tests/   # Vitest + React Testing Library
├── *.test.tsx           # Páginas e componentes (ex.: UsersListPage, UserForm)
├── *.test.ts            # Utilitários e store (ex.: format, date, auth.store)
└── guards.test.tsx      # Guards de rota
```

## Cobertura mínima esperada

- Services (backend): **80%+ de linhas e de branches** — confira com `make test-coverage`; o comando falha abaixo disso (ver [Testes unitários](backend-unit.md#cobertura)).
- Routers/endpoints (backend): todos os status codes documentados cobertos.
- Frontend (`packages/ui` e `apps/*`): **80%+ de linhas e de branches** — confira com `make test-coverage-front`; o comando falha abaixo disso. Além do número, os fluxos principais (formulários, autenticação, listagens) precisam estar cobertos por testes de comportamento.
