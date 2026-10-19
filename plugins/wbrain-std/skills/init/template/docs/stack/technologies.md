# Tecnologias

[← Stack](stack.md)

## Backend
- Python 3.12+, FastAPI, Pydantic v2
- SQLAlchemy 2.x (async) + PostgreSQL 17 + Alembic
- Auth sem senha: OTP por e-mail (Resend/SendGrid) + JWT (python-jose) — ver [Autenticação](../auth/auth.md)
- Testes: Pytest + pytest-asyncio + httpx + factory-boy
- Lint/format: Ruff; tipagem: mypy

## Frontend
- TypeScript, React 19, Vite, React Router v6+
- Estado: Zustand (simples) ou Redux Toolkit (complexo)
- Estilo: Tailwind CSS v4 (CSS-first, tokens OKLCH) + Shadcn/UI (pacote `radix-ui` unificado)
- Formulários: React Hook Form + Zod
- i18n: `react-i18next` (locale padrão `pt-BR`)
- Ícones: **exclusivamente** Remix Icon (`@remixicon/react`)
- Testes: Vitest + React Testing Library
- Lint/format: ESLint + Prettier

---

**Veja também:** [Infraestrutura](infrastructure.md) · [Backend](../backend/backend.md) · [Frontend](../frontend/frontend.md)
