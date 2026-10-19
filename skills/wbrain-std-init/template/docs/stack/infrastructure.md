# Infraestrutura

[← Stack](stack.md)

Docker + Docker Compose, com desenvolvimento 100% via containers (sem instalação local).

**Nginx é o ponto de entrada único** — nunca exponha backend ou frontend diretamente:
- `:8084` (app web + backend na mesma origem): `/api/`, `/docs`, `/redoc`, `/health` → backend (`:8000`); o restante → frontend (`:5173`).
- `:8085`: Design System.

Isso elimina problemas de CORS em desenvolvimento e replica o comportamento de produção.

## Portabilidade de plataforma (ARM/x86)

Dev pode rodar em **ARM** (ex.: Apple Silicon) e prod em **x86_64**; os containers devem ser **arch-neutros**:

- Use apenas imagens base multi-arch oficiais (`amd64` + `arm64`); nada de dependência ou binário específico de arquitetura.
- **Nunca** fixe `platform:` no compose nem `--platform` no Dockerfile — a imagem é buildada nativamente no host onde roda.
- Diferença inevitável por arquitetura (ex.: baixar um binário) → branch via `TARGETARCH` no Dockerfile, nunca `amd64`/`arm64` hardcoded.
- Lockfiles (pip/uv, npm) não devem travar artefatos por arquitetura.

## Produção

O deploy fica em `deploy/` (ver [Deploy](deploy.md)). Em produção, a stack sobe com `docker-compose.yml` + `docker-compose.prod.yml`, e o `.env` vem do Secrets Manager; o contrato completo está em [deploy/CONTRACT.md](../../deploy/CONTRACT.md).

---

**Veja também:** [Deploy](deploy.md) · [Makefile](makefile.md) · [Estrutura de pastas](folder-structure.md)
