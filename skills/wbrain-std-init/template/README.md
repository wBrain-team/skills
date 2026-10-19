# App boilerplate

Boilerplate para novos projetos: backend FastAPI + PostgreSQL, frontend React + Vite com
design system próprio, tudo em containers atrás de um Nginx.

## Pré-requisitos

- Docker e Docker Compose. Nada mais precisa ser instalado na máquina — todo o
  desenvolvimento roda em containers.

## Como rodar

1. Copie `.env.example` para `.env` e preencha as variáveis.
2. `make install` — builda as imagens.
3. `make start` — sobe os containers.
4. `make migrate` — aplica as migrations.
5. Acesse:
   - App: http://localhost:8084
   - API (OpenAPI): http://localhost:8084/docs
   - Design system: http://localhost:8085

Para popular o banco de desenvolvimento com dados fake: `make charge`.

## Comandos do dia a dia

| Comando | O que faz |
|---|---|
| `make test` | Testes do backend e do frontend |
| `make lint` / `make format` | Linters / formatação |
| `make logs` | Logs dos containers |
| `make restart` | Reinicia a stack do zero |

Lista completa em [docs/stack/makefile.md](docs/stack/makefile.md).

## Onde está cada coisa

- [specs/specs.md](specs/specs.md) — **fonte da verdade** do produto: o que o sistema faz,
  requisitos, modelo de dados e endpoints. Mantido por pessoas.
- [docs/docs.md](docs/docs.md) — como o sistema é implementado: arquitetura, padrões,
  testes e convenções.
- [docs/decisions/](docs/decisions/decisions.md) — registro das decisões técnicas (ADRs).
- [AGENTS.md](AGENTS.md) — instruções para agentes de IA.
- [deploy/](docs/stack/deploy.md) — deploy na AWS (`./deploy/deploy.sh`): infra, primeiro deploy e operação.
