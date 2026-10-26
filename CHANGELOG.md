# Changelog

## 0.7.0
- STD passa a significar **Source-of-Truth-Driven** (antes Spec-Test-Driven).
- O artefato "spec" passa a se chamar **snapshot**, para não confundir com o uso de "spec" no mercado (documento de mudança). A pasta `specs/` vira `snapshots/` (e `specs/specs.md` vira `snapshots/snapshots.md`), a skill `spec` vira `snapshot`, `spec-lint.md` vira `snapshot-lint.md`, `spec-coverage.sh` vira `snapshot-coverage.sh` e o marcador de teste `# spec:` vira `# snapshot:`.
- `AGENTS.md` do template explicita a divisão: `snapshots/` diz o que a aplicação faz (negócio); `docs/` diz como ela é construída (técnica).
- Projetos existentes precisam renomear `specs/` para `snapshots/` e os marcadores `spec:` dos testes para `snapshot:`.

## 0.6.0
- `tuning` só roda numa branch cujo diff contra a `main` é apenas de `specs/`. Com alterações de outra natureza (código, docs, trabalho de uma `loop`), o `preflight.sh` sai com código `4` e a skill orienta o tutor: integrar o trabalho à `main` primeiro, levar as specs para uma branch nova ou usar a `loop`. Uma tuning já em andamento na branch (estado existente) não é recusada.
- Regra "tuning ou loop": na `tuning` a spec é a entrada; na `loop`, a saída. A `loop` recomenda a `tuning` quando a branch só tem alterações em `specs/`; a `tuning` sugere a `loop` quando não há mudança de spec. `spec`, `onboard` e README apontam o critério.
- Branch `main`/`master` tratada igual em todas as skills, no padrão da `loop`: nada é produzido nela; a skill propõe uma branch com `AskUserQuestion` e só a cria com o ok do tutor.
- `loop`: a guarda de branch é a primeira ação, e o arquivo de estado só é criado com a branch definida (evita estado com nome errado). Garante `.std/` no `.gitignore`.
- `preflight.sh` recusa `master` e aceita `master`/`origin/master` como base.
- Scripts chamados sempre por `bash ${CLAUDE_PLUGIN_ROOT}/skills/...`. `loop` e `tuning` passam a conferir links também em `specs/`.
- Eval `12-tuning-recusa-branch-com-codigo`.

## 0.5.0
- Nova skill `loop` (desenvolvimento padrão): entrevista o tutor sobre Contexto, Problema e Pedido (com `AskUserQuestion` como apoio), investiga o projeto com subagentes, fatia o trabalho, propõe plano e, com o aceite, implementa em TDD atualizando `docs/` e `specs/`. Na `main`, propõe uma branch e só a cria com o ok. Ajustes fora do escopo levam à recomendação de nova conversa. Estado em `.std/loop/<branch>.md`.
- Referências antigas ao fluxo guiado pelo diff de `specs/` nas skills `spec`, `onboard` e `design-system` passam a apontar para a `tuning`.
- Evals `10-loop-sem-codigo-antes-do-aceite` e `11-loop-main-nao-produz`.

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
