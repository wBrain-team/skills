# Migrações de projeto entre versões do wbrain-std

Lido pela `wbrain-std:config` (etapa de migração) para atualizar um projeto existente à versão atual do plugin. Cada entrada descreve **como detectar** que o projeto ainda está no formato antigo, a **ação estrutural**, os **termos a varrer no conteúdo** e os **falsos positivos** conhecidos.

## Como usar (para a skill `config`)

- Aplique, **em ordem cronológica**, todas as entradas com versão maior que `plugin_version` do `.std/config.json` (ausente = projeto anterior ao config: considere todas) e menor ou igual à versão atual do plugin. Em cada entrada, só aja se o **sintoma** estiver presente; sem sintoma, a entrada não se aplica (o projeto já nasceu no formato novo).
- Migrações encadeadas (ex.: `specs` → `snapshots` → `snaps`) devem ser **colapsadas**: vá direto ao estado final (`specs/` → `snaps/`), sem passos intermediários.
- A mudança **estrutural** (renomear) nunca basta: varra o conteúdo do projeto inteiro atrás dos termos antigos (`AGENTS.md`, `CLAUDE.md`, `README.md`, `docs/**`, `snaps/**`, `.claude/settings.json`, `.gitignore`, scripts, testes, `Makefile`, CI), respeitando os falsos positivos.
- Entradas **automáticas** são aplicadas com o ok do usuário após mostrar o plano. Entradas **guiadas** só são explicadas e transformadas em pendências para o usuário (mudam decisões do projeto).
- Use `git mv` para renomear. Nunca apague conteúdo do usuário.

## Regra de manutenção

Toda versão do plugin que exija mudança em projetos existentes **adiciona uma entrada aqui no mesmo PR**, atualiza a skill `config` se a lógica genérica não cobrir o caso, adiciona um eval de migração e avisa no `CHANGELOG.md` (ver `CONTRIBUTING.md`).

---

## 0.10.0 — `.std/config.json` (automática)

- **Sintoma:** `.std/config.json` ausente.
- **Ação:** não há renomeação. Entreviste o usuário sobre a branch base e grave o config (etapas 1 a 2 da `config`). Garanta `.std/` no `.gitignore`.
- **Varrer:** nada.

## 0.9.0 — `snapshot` → `snaps` (automática)

- **Sintoma:** pasta `snapshots/` (ou `specs/`) na raiz; `snapshots/snapshots.md`; marcadores `# snapshot:` / `// snapshot:` (ou `spec:`) nos testes.
- **Ação estrutural:** `git mv snapshots snaps` (ou `specs snaps`); `snaps/snapshots.md` (ou `specs.md`) → `snaps/snaps.md`; marcadores dos testes → `# snap:` / `// snap:`.
- **Termos a varrer (antigo → novo):**
  - `snapshots/` → `snaps/`; `specs/` → `snaps/`
  - `snapshots.md` / `specs.md` → `snaps.md`
  - `snapshot:` / `spec:` (marcador) → `snap:`
  - `/wbrain-std:snapshot` / `/wbrain-std:spec` → `/wbrain-std:snaps`
  - `snapshot-lint.md` / `spec-lint.md` → `snaps-lint.md`; `snapshot-coverage.sh` / `spec-coverage.sh` → `snaps-coverage.sh`
  - Prosa: "snapshot(s)" / "spec(s)" referindo-se ao artefato de negócio → "snap(s)", mantendo gênero e número (ex.: "os snapshots" → "os snaps"); "Spec-Test-Driven" → "Source-of-Truth-Driven".
- **Onde procurar:** `AGENTS.md` (gerado pela `init`; descreve a divisão `snaps/` = negócio × `docs/` = técnica), `CLAUDE.md`, `README.md`, `docs/**` (inclui `docs/docs.md` e as guidelines), `snaps/snaps.md` (índice e links relativos), `.claude/settings.json`, `.gitignore`, `Makefile`, scripts, CI e testes.
- **Falsos positivos:** "snapshot" de infraestrutura (backup do volume na AWS, em `deploy/**` e `docs/stack/infrastructure.md`); "spec" em palavras como `inspect`, `respect`, `specification` de terceiros, `*.spec.ts` (convenção de nome de teste do Vitest/Jest) e `pytest` `spec`; "snapshot" de testes de snapshot de UI (ex.: `toMatchSnapshot`). Em caso de dúvida, pergunte.
- **Validação:** `bash ${CLAUDE_PLUGIN_ROOT}/skills/shared/scripts/check-doc-links.sh` e `bash ${CLAUDE_PLUGIN_ROOT}/skills/shared/scripts/snaps-coverage.sh`.

## 0.8.0 — Docker, `node_modules` em volumes e cobertura de 80% (guiada)

- **Sintoma:** frontend em Docker sem volumes de `node_modules` (compose sem `node_modules` em `volumes`), `docs/stack/infrastructure.md` sem a seção de `node_modules`, `docs/testing/**` com mínimo de 90% nos services ou sem alvo `make test-coverage-front`.
- **Ação:** não altere nada sozinho. Liste as pendências para o usuário (ADR-0006, `make test-coverage-front`, limite do `vitest.config.ts`, `pytest-cov` com `branch = true` e `fail_under = 80`, meta de 80% nos `docs/`) e sugira tratá-las com a `wbrain-std:loop`.

## 0.7.0 — `spec` → `snapshot` (coberta pela 0.9.0)

Projetos que ainda estão em `specs/` vão direto para `snaps/` pela entrada 0.9.0. O `AGENTS.md` do template ganhou a divisão `snapshots/` (negócio) × `docs/` (técnica): se o `AGENTS.md` do projeto não a tem, mostre o trecho atual do template (`${CLAUDE_PLUGIN_ROOT}/skills/init/template/AGENTS.md`) e proponha incorporá-lo.

## 0.4.0 — `loop` → `tuning` (automática)

- **Sintoma:** estado antigo em `.std/loop/*.md` criado pela skill anterior (formato de tuning: seções de diff de specs/snaps).
- **Ação:** estados em `.std/loop/` com formato de tuning são movidos para `.std/tuning/` (`git mv` não se aplica: `.std/` é ignorada, use `mv`). Estados no formato da `loop` atual (com Contexto/Problema/Pedido) ficam onde estão.
- **Varrer:** referências a `/wbrain-std:loop` em docs que descrevam o ajuste fino a partir do diff de snaps → `/wbrain-std:tuning`.
- **Falsos positivos:** a `loop` atual (desenvolvimento padrão) é outra skill e mantém o nome.
