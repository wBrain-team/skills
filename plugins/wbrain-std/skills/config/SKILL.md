---
name: config
description: Configura o projeto para as skills wbrain-std (hoje, a branch base usada nas comparações de diff, gravada em `.std/config.json`) e migra projetos existentes para a versão atual do plugin — renomeia pastas e corrige referências no conteúdo (AGENTS.md, README, docs). Use apenas quando o usuário pedir explicitamente para configurar ou atualizar o projeto wbrain-std, ou quando outra skill orientar a rodar `/wbrain-std:config`.
disable-model-invocation: true
---

# wbrain-std:config

Skill da série **wbrain-std** — STD = **Source-of-Truth-Driven**, a técnica da wbrain para desenvolvimento com IA: o `snaps/` é a fonte da verdade, e a implementação avança em TDD estrito a partir dele.

As skills `tuning`, `loop`, `snaps`, `onboard` e `design-system` comparam o diff da branch atual contra uma **branch base** e nunca produzem nela. Esta skill define qual é essa base (em `.std/config.json`) e **atualiza o projeto** quando uma versão nova do plugin muda algo fundamental (nome de pasta, marcador, formato). Pode ser chamada a qualquer momento para ajustar a configuração.

Siga as etapas **na ordem**. Fale com o usuário em pt-BR.

## Referências

- Migrações por versão: `../shared/migrations.md`.
- Leitura do config pelas outras skills: `bash ${CLAUDE_PLUGIN_ROOT}/skills/shared/scripts/std-config.sh`.
- Versão atual do plugin: campo `version` de `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.

## Schema do `.std/config.json`

```json
{ "schema_version": 1, "base_branch": "main", "plugin_version": "0.10.0" }
```

- `base_branch`: branch contra a qual o diff é calculado. Também é protegida: nenhuma skill produz nela (além de `main` e `master`, sempre protegidas).
- `plugin_version`: última versão do plugin para a qual as migrações já foram aplicadas **neste projeto**.
- `schema_version`: versão do formato do próprio arquivo.

O arquivo é **local de cada pessoa** (`.std/` fica no `.gitignore`).

## Parâmetros

| Chave | Pergunta da entrevista | Padrão sugerido |
|---|---|---|
| `base_branch` | Contra qual branch o diff deve ser comparado? | a candidata detectada (`main`, `master` ou `develop`) |

Novos parâmetros entram nesta tabela, na entrevista (etapa 2) e no schema acima.

## 0. Guarda

- Não é repositório git → **recuse e encerre**.
- Esta skill roda em **qualquer branch**, inclusive a base: ela só grava `.std/config.json` (ignorado pelo git) e, na migração, altera arquivos do projeto **somente com o ok** do usuário (etapa 3). Antes de migrar, se houver alterações locais não commitadas, avise e peça que o usuário commite ou guarde antes de seguir.
- Garanta `.std/` no `.gitignore` (acrescente a linha se faltar; só isso).

## 1. Estado atual

Leia `.std/config.json` (se existir) e a versão do plugin. Mostre em poucas linhas: base atual, `plugin_version` do projeto e versão instalada. Sem arquivo → diga que o projeto ainda não foi configurado.

## 2. Entrevista

Uma pergunta por vez, partindo do que foi descoberto no projeto (`git branch -a`, `git remote show origin` se houver remoto), não de uma pergunta em branco.

1. **Branch base.** Proponha a candidata detectada com `AskUserQuestion`, "(Recomendado)" primeiro, e as outras branches plausíveis (`main`, `master`, `develop`, a branch padrão do remoto). Aceite também outra branch digitada. Explique em uma frase que as skills comparam o diff contra ela e não produzem nela.
2. **Validação.** Confirme que a ref existe (`git rev-parse --verify <base>` ou `origin/<base>`). Se não existir, avise e pergunte de novo; não grave uma base inexistente.
3. Com config já existente, pergunte só o que o usuário quer mudar; mantenha o resto.

Nada é gravado antes da confirmação do resumo ("base: `<base>`. Posso gravar?").

## 3. Migração do projeto

1. Leia `../shared/migrations.md` e a versão atual do plugin. Compare com `plugin_version` do config (ausente = projeto anterior ao config).
2. Para cada entrada pendente, **em ordem cronológica**, detecte o sintoma no projeto. Sem sintomas em nenhuma entrada → diga que o projeto já está atualizado e vá à etapa 4.
3. Para as entradas **automáticas** com sintoma, monte o plano **completo** e mostre-o antes de qualquer alteração:
   - **estrutura:** renomeações (`git mv`) com origem e destino;
   - **conteúdo:** a varredura obrigatória das referências aos termos antigos, **no projeto inteiro** (não só nos arquivos renomeados): `AGENTS.md` e `CLAUDE.md` da raiz, `README.md`, `docs/**`, `snaps/**` (índice e links), `.claude/settings.json`, `.gitignore`, `Makefile`, scripts, CI e testes. Use `grep -rnIE` com os termos da entrada, excluindo os falsos positivos documentados nela. Liste arquivo, linha e a troca proposta (amostra do diff; agrupe por arquivo se for longo);
   - **ambiguidades:** ocorrências que podem ser falso positivo vão numa lista separada para o usuário decidir; na dúvida, não altere.
4. Aplique **só com o ok** do usuário. Mudanças de conteúdo respeitam gênero e número (ex.: "os snapshots" → "os snaps"). Não apague nem reescreva conteúdo do usuário além das trocas listadas.
5. Entradas **guiadas**: não altere nada; apresente as pendências como lista para o usuário e sugira a `wbrain-std:loop` para tratá-las.
6. **Validação:** rode `bash ${CLAUDE_PLUGIN_ROOT}/skills/shared/scripts/check-doc-links.sh` e `bash ${CLAUDE_PLUGIN_ROOT}/skills/shared/scripts/snaps-coverage.sh` (quando houver `snaps/`) e repita o `grep` pelos termos antigos para provar que só restam falsos positivos. Falhou → reporte e corrija antes de registrar a versão.
7. Não commite: deixe as mudanças no working tree e diga ao usuário que revise o diff e commite (nunca na branch base).

## 4. Gravação e resumo

- Grave `.std/config.json` com `schema_version`, `base_branch` e `plugin_version` = versão atual do plugin. **Só registre `plugin_version` após a migração concluída e validada** (ou se não havia o que migrar); se o usuário recusou a migração, preserve o valor anterior (ou omita a chave, se nunca existiu) para a skill oferecer a migração de novo na próxima chamada.
- Resumo curto ao usuário: base configurada, o que foi migrado (renomeações e arquivos reescritos), pendências guiadas e o próximo passo (revisar e commitar a migração).

## Regras

- Nunca grave `.std/config.json` com base inexistente.
- Nunca altere arquivos do projeto sem mostrar o plano e receber o ok.
- A migração varre o conteúdo, não só nomes de pasta.
- Toda alteração nas skills que exija migração em projetos existentes exige uma entrada nova em `../shared/migrations.md` (ver `CONTRIBUTING.md`).
