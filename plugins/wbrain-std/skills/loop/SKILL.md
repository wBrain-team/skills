---
name: loop
description: Conduz o desenvolvimento padrão de um pedido do tutor (nova feature, correção de bug, melhoria, refactor ou remoção) — entrevista o usuário para entender Contexto, Problema e Pedido, investiga o projeto com subagentes, fatia o trabalho, propõe um plano e, com o aceite, implementa em TDD, atualizando `docs/` e `snapshots/`. Use apenas quando o usuário pedir explicitamente para rodar a loop wbrain-std.
disable-model-invocation: true
---

# wbrain-std:loop

Skill da série **wbrain-std** — STD = **Source-of-Truth-Driven**, a técnica da wbrain para desenvolvimento com IA: o `snapshots/` é a fonte da verdade, e a implementação avança em TDD estrito a partir dele.

A `wbrain-std:init` cria projetos novos, a `wbrain-std:onboard` traz projetos existentes para o padrão, a `wbrain-std:snapshot` ajuda a escrever snapshots, a `wbrain-std:tuning` faz o ajuste fino a partir do diff de `snapshots/` e a `wbrain-std:design-system` cuida da interface. Esta skill é o **desenvolvimento padrão**: o tutor traz um pedido em linguagem natural e o agente o transforma em entrega, do entendimento ao commit, mantendo `snapshots/` e `docs/` coerentes com o código.

Siga as etapas **na ordem**. Fale com o usuário em pt-BR. Leia `AGENTS.md` antes de começar.

## Referências

Caminhos relativos à pasta desta skill (`${CLAUDE_PLUGIN_ROOT}/skills/loop/`):
- `templates/state.md` e `templates/plan-summary.md`: modelos do arquivo de estado e do resumo do plano.
- `../shared/subagentes.md`, `../shared/snapshot-lint.md`, `../shared/rastreabilidade.md`: regras comuns do kit.
- `../snapshot/guia-de-escrita.md`: como escrever snapshots.
- `../design-system/novo-componente.md`: roteiro para pensar um componente novo.
- `../tuning/review.md`: guia do subagente revisor (etapa 8).
- `bash ${CLAUDE_PLUGIN_ROOT}/skills/shared/scripts/check-doc-links.sh [caminho...]`: links internos quebrados em `docs/` e `snapshots/`.
- `bash ${CLAUDE_PLUGIN_ROOT}/skills/shared/scripts/snapshot-coverage.sh [snapshot...]`: relação snapshot → testes pelo marcador `snapshot:`.

## Regras transversais (valem em todas as etapas)

### O principal conversa e orquestra
Siga `../shared/subagentes.md`. O agente principal mantém o **diálogo com o tutor** e a **orquestração**; o trabalho pesado vai para subagentes, para o contexto ficar enxuto:
- `Explore`: investigar código, testes, `docs/` e `snapshots/`;
- `Plan`: montar o plano, analisar cenários hipotéticos e alternativas;
- `general-purpose`: escrever testes e código, analisar falhas de testes, revisar o resultado.

Não leia arquivos grandes no principal quando um subagente pode trazer o resumo.

### Nada é produzido antes do aceite
- Até a aprovação do plano (etapa 5), **nada é gravado** no projeto além do arquivo de estado em `.std/loop/`. Propostas aparecem **no chat**.
- Nunca produza na `main` (etapa 0).

### Condução da conversa
- **Uma pergunta por vez**, em diálogo. Enquanto o usuário colabora, use perguntas **abertas** e aprofunde quando a resposta abrir algo relevante.
- Pergunte **a partir do que foi descoberto** no projeto: "Vi X em `caminho`. É esse o ponto de partida?".
- **Fallback de baixa colaboração:** se o usuário der respostas curtas ou vagas (uma ou poucas palavras, "não sei", "tanto faz", "pode ser") em duas perguntas, ou disser que não sabe explicar, passe a usar `AskUserQuestion` com opções concretas e viáveis, montadas a partir do que os subagentes descobriram. A opção recomendada vem primeiro, marcada "(Recomendado)". O usuário sempre pode responder "Outro". Se ele voltar a dar respostas ricas, retome as perguntas abertas.
- **Seja propositivo:** o tutor às vezes descreve uma solução por falta de referência. Se houver um padrão melhor (no projeto, em `docs/` ou na prática do mercado), recomende-o, explique em uma ou duas frases por quê e deixe a decisão com ele.

### Fatiar sempre
Pedido grande é a principal causa de entrega errada e de contexto inchado. Prefira a **menor fatia que entrega valor**; o resto vira próximas fatias, cada uma em nova conversa. Isso vale mesmo quando o tutor pede tudo de uma vez: proponha o fatiamento e explique o ganho.

### Estado (`.std/loop/<branch>.md`)
Use o modelo em `templates/state.md`. A pasta `.std/` fica fora do git. Atualize o arquivo **ao fim de cada etapa e de cada tarefa**: ele é a memória da loop, o contexto da conversa não é. Mantenha-o enxuto: resumos e caminhos, nunca código.

### Testes
- Siga `docs/guidelines/tdd.md`, `docs/testing/` (a partir de `testing.md`) e `docs/guidelines/agent-behavior.md` (Docker, sem instalar dependências na máquina local, fixtures/factories, isolamento do banco).
- Na implementação, rode só testes **pontuais** (um arquivo ou um teste). A **suíte completa** roda só na etapa 8.
- **Testes sempre em série:** só o principal, ou um único subagente por vez, roda testes.
- Limites: até **10** tentativas no mesmo teste pontual e até **5** rodadas na suíte completa. Ao atingir um limite, pare, registre `status: bloqueado` e reporte o que foi tentado, a falha e as hipóteses; o tutor decide se continua ou orienta.

## 0. Guarda de branch

É a **primeira ação** da skill, antes de qualquer leitura de estado ou pergunta sobre o pedido: o nome da branch define o arquivo de estado. Rode `git branch --show-current` e `git status --short`.

- Branch `main`, `master` ou HEAD destacado → **não produza nada nela**. Proponha com `AskUserQuestion` um nome de branch no padrão de `docs/guidelines/git.md` (`feat/<descrição>`, `fix/<descrição>`, `chore/<descrição>`), com base no que o tutor já disse do pedido, e **crie a branch só com o ok** do tutor. Sem ok, a entrevista pode seguir, mas nada é gravado, nem o arquivo de estado; a branch volta a ser pedida antes do plano (etapa 5).
- Alterações locais não commitadas → avise e pergunte se fazem parte do pedido antes de seguir.

## 1. Retomada

Só com a branch definida (etapa 0). Se `.std/loop/<branch>.md` existe, leia e retome da etapa registrada, sem refazer entrevista ou plano já aprovados. Se `status: concluído`, trate a conversa como etapa 10 (ajustes) ou, se o pedido for outro, como uma loop nova (mova o resumo anterior para **Histórico**).

Sem arquivo → antes de criá-lo, confira o diff da branch contra a `main` (`git diff --name-only main...HEAD`, `git status --short`). Se ele tiver **só** alterações em `snapshots/`, o tutor provavelmente já escreveu a mudança no snapshot: recomende a `wbrain-std:tuning`, que implementa exatamente esse diff, e explique em uma frase (na tuning o snapshot é a entrada; na loop, a saída). Só siga com a loop se o tutor preferir; nesse caso, as mudanças de snapshot entram como contexto da entrevista.

Então crie o arquivo com `status: entrevista` e garanta `.std/` no `.gitignore`.

## 2. Entrevista: Contexto, Problema e Pedido

O objetivo é entender três coisas:
- **Contexto:** em que circunstâncias o pedido existe, onde ele se encaixa e quais os limites (quem usa, que parte do sistema, o que não pode mudar).
- **Problema:** dentro desse contexto, qual o problema fundamental a resolver (não a solução imaginada).
- **Pedido:** o que exatamente o tutor quer que seja feito.

Como conduzir:
1. Comece pelo que o tutor já disse; pergunte só o que falta.
2. Assim que o assunto ficar claro o bastante, dispare **subagentes `Explore` em paralelo** (até ~3: código e testes da área, `docs/` aplicáveis, `snapshots/` relacionados). Retorno exigido: arquivos relevantes (`caminho:linha`), comportamento atual, testes existentes, regras de `docs/` que se aplicam, lacunas e **casos de borda** que o pedido não cobre.
3. Use o retorno para fazer perguntas melhores: gaps, corner cases, permissões, erros, números concretos, o que **não** faz parte. Continue perguntando enquanto a inferência tiver chance real de falhar; o que o contexto resolve com segurança vira premissa registrada, não pergunta.
4. **Classifique** o pedido: nova feature, correção de bug, melhoria, refactor ou remoção (pode haver mais de uma). Em bug, peça ou descubra os passos de reprodução: o primeiro teste reproduz o bug.
5. Devolva um **resumo** (Contexto, Problema, Pedido, classificação, premissas) e peça confirmação. Registre no estado. Só avance com a confirmação.

## 3. Fatiamento

Se o pedido couber em poucas tarefas de uma ou duas camadas, siga com uma fatia só. Caso contrário, proponha **fatias** independentes e entregáveis: a primeira é a menor que resolve o problema de ponta a ponta; as seguintes são evoluções. Mostre o ganho (menos risco, revisão mais fácil, contexto menor) e deixe o tutor escolher. Registre a fatia atual e as próximas no estado; esta conversa implementa **só a fatia atual**.

## 4. Design system (só com frontend)

Se a fatia envolve interface, peça ao subagente de exploração (ou a um novo) que compare as telas com os componentes do design system (`packages/ui`, `docs/frontend/design-system.md`). Se houver elementos repetidos ou genéricos que merecem virar componente, **proponha** a criação seguindo `../design-system/novo-componente.md` (estados, API, acessibilidade), como tarefa do plano ou como fatia própria. Se o projeto não tem design system, sugira a skill `wbrain-std:design-system` antes.

## 5. Plano e aceite

Dispare um subagente `Plan` com o resumo da etapa 2, a fatia escolhida e os retornos dos subagentes. O plano deve:
- seguir `docs/`, em especial **TDD**: teste antes da implementação em cada tarefa, com testes úteis centrados em regra de negócio e o marcador `snapshot:` (`../shared/rastreabilidade.md`);
- dividir em tarefas pequenas, marcando **paralelizáveis** (arquivos disjuntos) e **sequenciais**, com o **comando de teste pontual** de cada uma;
- em remoções, prever a retirada do código e dos testes obsoletos;
- trazer o **mapa de documentação**: arquivos de `snapshots/` (documentação humana, comportamento) e de `docs/` (técnica) a criar, editar ou remover, incluindo os que podem ficar **desatualizados** pela mudança (drift);
- terminar com dúvidas e premissas.

Ainda na `main` (o tutor recusou a branch na etapa 0)? Peça a branch de novo antes de apresentar o plano; sem ela, entregue o resumo do entendimento e encerre.

Apresente o resumo com `templates/plan-summary.md`, registre `status: aguardando aprovação` e **pare**. Ajustes pedidos pelo tutor voltam para o plano; só siga com um "seguir" claro. Registre `plano aprovado: <data>`.

## 6. Implementação

Ciclo por tarefa: **teste vermelho → implementação mínima → teste verde → refactor**, com testes pontuais.

- **Sequenciais:** o principal dispara um subagente `general-purpose` por tarefa (ou implementa, se for trivial), que pode rodar os testes pontuais dela.
- **Paralelizáveis:** subagentes `general-purpose` em paralelo com `isolation: "worktree"`, primeiro só os testes e depois só a implementação, **sem rodar testes**; o principal integra e roda os testes pontuais um por vez (vermelho, depois verde). Conflito não trivial → refaça a tarefa em sequência.
- O prompt de cada subagente traz a tarefa, os arquivos, as regras de `docs/`, o comando de teste e se pode rodá-lo. Nunca dois subagentes no mesmo arquivo. Retorno: arquivos alterados, testes e resultado, pendências.
- Marque cada tarefa no estado ao concluir. Ambiguidade nova que mude comportamento → pergunte ao tutor antes de seguir.

## 7. Documentação (`snapshots/` e `docs/`)

Ao fim de cada tarefa ou grupo, aplique o mapa de documentação do plano:
- **`snapshots/`**: descreva o comportamento entregue, seguindo `../shared/snapshot-lint.md` e `../snapshot/guia-de-escrita.md` (presente, testável, um assunto por arquivo, alcançável a partir de `snapshots/snapshots.md`).
- **`docs/`**: registre o que é técnico; decisões relevantes viram ADR em `docs/decisions/`, registrado em `decisions.md`. Mantenha índices e links **Veja também**.
- **Anti-drift:** peça a um subagente `Explore` que procure em `snapshots/` e `docs/` trechos que a mudança tornou falsos (comportamento, nomes, rotas, valores) e corrija-os.
- Rode `bash ${CLAUDE_PLUGIN_ROOT}/skills/shared/scripts/check-doc-links.sh docs snapshots` e corrija links quebrados.

## 8. Validação e revisão

1. Rode a **suíte completa** e o lint uma única vez (`make test`, testes de frontend se existirem, `make lint`). Falhas → corrija com testes pontuais e rode a suíte de novo no fim (limite de 5 rodadas).
2. Dispare um subagente `general-purpose` **somente leitura** (sem editar nem commitar) com o resumo da etapa 2, o plano e a instrução de seguir `../tuning/review.md`, comparando o pedido aprovado com o diff de código, testes, `snapshots/` e `docs/`. Bloqueantes → corrija, rode a suíte e faça **uma** nova revisão. Sugestões baratas e no escopo → aplique; as demais vão para o relatório.

## 9. Commits e relatório

- Commite só na branch atual, seguindo `docs/guidelines/git.md` (Conventional Commits), em commits granulares. Nunca use `--no-verify` nem faça push sem pedido.
- Atualize o estado: `status: concluído` e `commit de conclusão: <hash>`.
- Relatório curto: o que mudou por camada, testes e resultado da suíte, `snapshots/` e `docs/` atualizados, commits, premissas e **próximas fatias** sugeridas. Peça ao tutor que avalie a entrega.

## 10. Ajustes pós-entrega

O tutor pode pedir correções e ajustes. Antes de agir, compare o pedido com o Contexto, o Problema e a fatia registrados no estado:
- **Dentro do escopo** (corrige ou refina o que foi entregue) → trate como uma mini-loop: teste primeiro, implementação, docs/snapshots, testes pontuais e suíte no fim, commit.
- **Fora do escopo** (outro problema, outra fatia, nova funcionalidade) → **recomende iniciar uma nova conversa** com a loop, explicando que isso evita desalinhamento com o pedido original e contexto inchado. Registre o pedido como próxima fatia no estado e ofereça um resumo curto para colar na nova conversa. Só siga nesta conversa se o tutor insistir explicitamente.

## Limites

- Nunca produza na `main`. Crie branch só com o ok do tutor.
- Nada gravado no projeto antes do aceite do plano, exceto `.std/loop/` (e só com a branch definida).
- Uma fatia por conversa.
