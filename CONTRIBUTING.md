# Contribuindo

1. Adicione ou edite skills em `plugins/wbrain-std/skills/<nome>/SKILL.md` (frontmatter com `name` igual ao diretório e `description`).
2. Mantenha referências entre skills por caminho relativo (`../outra-skill/...`).
3. **Sempre** aumente `version` em `plugins/<plugin>/.claude-plugin/plugin.json` (e em `marketplace.json`); sem isso os usuários não recebem a atualização.
4. Registre a mudança em `CHANGELOG.md`.
5. Valide com `claude plugin validate .` e teste localmente: `/plugin marketplace add .`
6. Abra um PR.

Skills independentes das atuais devem virar um novo plugin: crie `plugins/<novo>/` com seu `.claude-plugin/plugin.json` e `skills/`, e registre em `marketplace.json`.
