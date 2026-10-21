# Changelog

## Não lançado
- Agentes podem alterar `specs/` com aprovação do tutor; apenas a skill `loop` continua proibida de modificá-las (restrição descrita só no `SKILL.md` dela). O `AGENTS.md` do template passa a ter uma regra genérica, sem citar skills.
- `spec`: ao final apresenta o plano de modificação das specs e pergunta se o usuário quer atualização automática ou instruções para alterar por conta própria.
- `onboard`: a geração de specs deixa de ser tratada como exceção.

## 0.1.2
- Corrige `bad interpreter: Permission denied` ao rodar scripts: os `.sh` do plugin (loop e template `init/deploy`) agora têm o bit de execução no git, e as skills `loop`, `spec` e `onboard` chamam os scripts com `bash`.

## 0.1.1
- Skill `loop` mais tolerante a pequenos desvios de specs (ajustes em `SKILL.md`, `review.md`, `spec-lint.md` e nos templates `plan-summary.md` e `state.md`).

## 0.1.0
- Estrutura inicial do marketplace com o plugin `wbrain-std` e as skills `init`, `spec`, `loop` e `onboard` (invocadas como `/wbrain-std:<skill>`).
- Skills renomeadas, sem o prefixo `wbrain-std-` (agora é o nome do plugin). Caminhos de scripts usam `${CLAUDE_PLUGIN_ROOT}`.
