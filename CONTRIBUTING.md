# Contribuindo

1. Adicione ou edite skills em `plugins/wbrain-std/skills/<nome>/SKILL.md` (frontmatter com `name` igual ao diretório e `description`).
2. Mantenha referências entre skills por caminho relativo (`../outra-skill/...`). Scripts executados pelo agente usam o caminho absoluto `bash ${CLAUDE_PLUGIN_ROOT}/skills/...`, porque o Bash roda a partir da pasta do projeto.
3. **Sempre** aumente `version` em `plugins/<plugin>/.claude-plugin/plugin.json` (e em `marketplace.json`); sem isso os usuários não recebem a atualização.
4. Registre a mudança em `CHANGELOG.md`.
5. Valide com `claude plugin validate .` e teste localmente: `/plugin marketplace add .`
   Mudou uma `SKILL.md` ou regra em `shared/`? Rode os evals: `bash plugins/wbrain-std/evals/run.sh` (ou `run.sh 03` para um caso). Cada caso fica em `evals/cases/<nome>/` com `setup.sh`, `prompt.txt` e `check.sh`; as funções comuns estão em `evals/lib.sh`. Variáveis: `EVAL_MODEL`, `EVAL_BUDGET` (USD por caso, padrão 3), `EVAL_TIMEOUT` (s, padrão 900).
6. Abra um PR.

Skills independentes das atuais devem virar um novo plugin: crie `plugins/<novo>/` com seu `.claude-plugin/plugin.json` e `skills/`, e registre em `marketplace.json`.
