# Changelog

## Não lançado
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
