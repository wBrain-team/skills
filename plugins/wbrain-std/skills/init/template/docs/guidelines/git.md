# Git e versionamento

[← Diretrizes](guidelines.md)

## Conventional Commits
Formato obrigatório: `<tipo>(escopo): descrição curta`, com corpo opcional.

Tipos válidos: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`. Exemplos:
- `feat(auth): adiciona endpoint de refresh token`
- `fix(api): corrige validação de email no cadastro`

## Branches
- `main` — produção, protegida (exemplo: a branch base usada pelas skills `wbrain-std` é a definida em `.std/config.json`, via `/wbrain-std:config`)
- `develop` — integração
- `feat/<description>`, `fix/<description>`, `chore/<description>` — funcionalidades, correções, manutenção

---

**Veja também:** [Comportamento do agente](agent-behavior.md)
