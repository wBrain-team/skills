# wbrain-std (marketplace de plugins)

Antes de mexer em skills, leia `CONTRIBUTING.md`.

**Mudança que exige migração em projetos existentes** (renomear pasta/arquivo/marcador/skill, mudar formato de estado ou de template, novo parâmetro obrigatório no config) **deve atualizar no mesmo PR**: `plugins/wbrain-std/skills/shared/migrations.md`, a etapa de migração de `plugins/wbrain-std/skills/config/SKILL.md` (se preciso), um eval de migração e o `CHANGELOG.md`. A skill `config` precisa sempre ser capaz de levar um projeto antigo à versão atual do plugin. Confira com `bash plugins/wbrain-std/evals/check-migrations.sh`.
