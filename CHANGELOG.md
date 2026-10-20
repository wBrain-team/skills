# Changelog

## 0.1.1
- Skill `loop` mais tolerante a pequenos desvios de specs (ajustes em `SKILL.md`, `review.md`, `spec-lint.md` e nos templates `plan-summary.md` e `state.md`).

## 0.1.0
- Estrutura inicial do marketplace com o plugin `wbrain-std` e as skills `init`, `spec`, `loop` e `onboard` (invocadas como `/wbrain-std:<skill>`).
- Skills renomeadas, sem o prefixo `wbrain-std-` (agora é o nome do plugin). Caminhos de scripts usam `${CLAUDE_PLUGIN_ROOT}`.
