# Changelog

## 0.4.0
- Skill `loop` renomeada para `tuning`: o fluxo guiado pelo diff de `specs/` passa a ser posicionado como ajuste fino da aplicação. O estado fica em `.std/tuning/<branch>.md`. O nome `loop` fica reservado para uma futura skill de desenvolvimento padrão.
- `check-doc-links.sh` e `spec-coverage.sh` movidos para `skills/shared/scripts/`, e `plan-summary.md` para `skills/shared/templates/` (usados por várias skills).
- Evals passam a invocar `/wbrain-std:tuning`.

## 0.3.0
- Nova skill `design-system`: entrevista enxuta (com imagens de referência e `AskUserQuestion` como apoio), propostas de direção visual que fogem do visual genérico, fundação (tokens e componentes básicos) ou desenho de componente novo com decisões antecipadas; implementa após aprovação e atualiza `docs/` e `specs/componentes/`.
- Template: `docs/frontend/design-system.md` com a anatomia das páginas do showcase e o catálogo de componentes.
- Evals `08-ds-sem-codigo-antes-do-ok` e `09-ds-recusa-sem-frontend` (a skill recusa projetos só de backend).

## 0.2.0
- Agentes podem alterar `specs/` com aprovação do tutor; apenas a skill `loop` continua proibida de modificá-las (restrição descrita só no `SKILL.md` dela). O `AGENTS.md` do template passa a ter uma regra genérica, sem citar skills.
- `spec`: ao final apresenta o plano de modificação das specs e pergunta se o usuário quer atualização automática ou instruções para alterar por conta própria.
- `onboard`: a geração de specs deixa de ser tratada como exceção.
- Specs organizadas por domínio de negócio, com eixo (telas, endpoints ou eventos) declarado no topo de `specs/specs.md` (`spec`, `onboard` e template).
- Regras comuns em `skills/shared/`: `spec-lint.md` (movido de `loop/`), `subagentes.md` e `rastreabilidade.md`.
- Rastreabilidade spec → teste: marcador `# spec:`/`// spec:` nos testes e `loop/scripts/spec-coverage.sh`, usado no plano e na revisão do `loop`.
- `loop`: trilha curta para mudanças pequenas (lint, descoberta e plano sem cerimônia; aprovação, TDD, suíte e revisão mantidos).
- Evals das skills em `plugins/wbrain-std/evals/` (`run.sh`, via `claude -p`).

## 0.1.2
- Corrige `bad interpreter: Permission denied` ao rodar scripts: os `.sh` do plugin (loop e template `init/deploy`) agora têm o bit de execução no git, e as skills `loop`, `spec` e `onboard` chamam os scripts com `bash`.

## 0.1.1
- Skill `loop` mais tolerante a pequenos desvios de specs (ajustes em `SKILL.md`, `review.md`, `spec-lint.md` e nos templates `plan-summary.md` e `state.md`).

## 0.1.0
- Estrutura inicial do marketplace com o plugin `wbrain-std` e as skills `init`, `spec`, `loop` e `onboard` (invocadas como `/wbrain-std:<skill>`).
- Skills renomeadas, sem o prefixo `wbrain-std-` (agora é o nome do plugin). Caminhos de scripts usam `${CLAUDE_PLUGIN_ROOT}`.
