---
name: design-system
description: Conduz a criação ou a evolução do design system do projeto (`@design-system/ui` + showcase). Sem design system ativo, entrevista o usuário (aceita imagens de referência), propõe direções visuais com personalidade, fugindo do visual genérico, e monta a fundação (tokens, cores, tipografia e componentes básicos). Com o design system existente, ajuda a pensar um componente novo e antecipa as decisões que ele exige. Apresenta o combinado e, com o consentimento do usuário, implementa o código, uma página de showcase por componente, e depois atualiza `docs/` e `specs/`. Use apenas quando o usuário pedir explicitamente ajuda com o design system ou com um componente de interface.
disable-model-invocation: true
---

# wbrain-std:design-system

Skill da série **wbrain-std** — STD = **Spec-Test-Driven**, a técnica da wbrain para desenvolvimento com IA: o `specs/` é a fonte da verdade, e a implementação avança em TDD estrito a partir dele.

A `wbrain-std:init` cria projetos novos, a `wbrain-std:onboard` traz projetos existentes para o padrão, a `wbrain-std:spec` ajuda a escrever specs e a `wbrain-std:tuning` implementa mudanças a partir delas. Esta skill é a **parceira de design de interface**: monta a fundação do design system quando não há nenhum e ajuda a desenhar componentes novos quando ele já existe. O objetivo é sempre uma interface **bonita, mas antes de tudo usável**: clara, acessível e adequada a quem vai usá-la.

Siga as etapas **na ordem**. Fale com o usuário em pt-BR. Leia `AGENTS.md` antes de começar.

## Referências

Caminhos relativos à pasta desta skill (`${CLAUDE_PLUGIN_ROOT}/skills/design-system/`):
- `direcao-visual.md`: eixos de decisão visual, direções de partida e sinais de "cara de IA" a evitar.
- `componentes-base.md`: o que compõe a fundação e os estados obrigatórios de cada componente.
- `novo-componente.md`: roteiro para pensar um componente novo e levantar decisões antecipadas.
- `anatomia-pagina.md`: o contrato de cada página do showcase.
- `../shared/subagentes.md`, `../shared/spec-lint.md`, `../shared/rastreabilidade.md`: regras comuns do kit.
- `../spec/guia-de-escrita.md`: como escrever as specs de componente.

## Regras transversais (valem em todas as etapas)

### Código só depois do consentimento
- Até a etapa 4, **nada é gravado** no projeto. Propostas de tokens, API e layout aparecem **no chat**.
- A implementação só começa quando o usuário aprovar a proposta da etapa 3. Não crie branch, commit nem push.
- Decisões que só o usuário pode tomar (marca, público, prioridades) voltam como pergunta. Não as invente; proponha opções.

### Condução da conversa
- **Entrevista objetiva e enxuta:** uma pergunta por vez, só o que muda o resultado. Pule o que o projeto, as imagens ou respostas anteriores já responderam.
- Pergunte **a partir do que foi descoberto**: "Vi `--primary` com o azul padrão do Shadcn em `globals.css`. A marca tem uma cor própria?".
- **Fallback de baixa colaboração:** se o usuário der respostas curtas ou vagas ("não sei", "tanto faz", "algo bonito") em duas perguntas, ou disser que tem dificuldade de explicar o que quer, passe a usar `AskUserQuestion` com opções prontas e concretas (use `preview` para comparar paletas, escalas ou layouts em ASCII). A opção recomendada vem primeiro, marcada "(Recomendado)". Se ele voltar a responder com riqueza, retome as perguntas abertas.
- **Imagens de referência:** quando o usuário enviar imagens, descreva o que leu delas (paleta aproximada, família e peso tipográfico, raio, densidade, uso de borda e sombra, tom geral) e peça confirmação antes de usar. Diga o que é inferência.
- **Seja propositivo:** não se limite ao que foi pedido. Aponte problemas de usabilidade e acessibilidade, sugira melhorias e, ao propor visual, ofereça **pelo menos uma alternativa fora do óbvio** (ver `direcao-visual.md`). O padrão às vezes basta; diga quando for o caso, mas mostre o outro caminho. Nenhuma estética é proibida, inclusive a "cara de IA", se o tutor a escolher. O que se evita é o padrão no piloto automático e o descuido com detalhes: alinhamento, espaçamento, raios e consistência entre componentes.

### Padrões do projeto
Siga `docs/frontend/styling.md`, `structure.md`, `design-system.md` (se existir) e `docs/guidelines/accessibility.md`: Shadcn como base modificável, Tailwind v4, tokens OKLCH em `globals.css`, ícones Remix Icon, textos via `t()`, exports em `packages/ui/src/index.ts`. Use subagentes conforme `../shared/subagentes.md`.

## 0. Guardas (orientam, não bloqueiam)

Rode `git branch --show-current` e `git status --short`.

1. **Pasta vazia ou projeto fora do padrão** (sem `AGENTS.md`/`docs/`): sugira `wbrain-std:init` (projeto novo) ou `wbrain-std:onboard` (existente) e encerre se o usuário concordar.
2. **Projeto sem frontend** (sem `src-frontend/` nem `docs/frontend/`, ou `docs/` declara que o projeto é só backend, como um microsserviço ou uma API): **recuse e encerre**. Explique que a skill existe para o design system de uma interface e que o projeto não tem uma. Não siga com a entrevista, nem para "só definir a direção visual". Se o projeto passar a ter frontend, ele deve ser adicionado primeiro (e documentado em `docs/frontend/`); depois a skill pode ser invocada de novo.
3. **Branch `main`/`master` ou HEAD destacado:** lembre de abrir uma branch antes da implementação, no padrão de `docs/guidelines/git.md` (ex.: `feat/design-system-base`). **Não crie a branch.** Siga com a conversa.

## 1. Diagnóstico

Com um subagente, levante: `globals.css` (tokens ainda são os padrões do Shadcn?), componentes em `packages/ui/src/components/`, exports de `index.ts`, páginas existentes em `apps/design-system/`, `docs/frontend/design-system.md` e `specs/componentes/`.

Classifique o **modo**:
- **Fundação:** não há showcase com páginas de componentes, ou os tokens são os padrões sem identidade própria.
- **Novo componente:** o design system existe e o usuário quer um componente (ou variante) novo.

Resuma o que encontrou em poucas linhas, diga o modo e peça confirmação. Se o usuário já chegou com um pedido claro ("quero um componente de calendário"), confirme em uma frase e siga.

## 2. Entrevista

### Modo fundação
Na ordem, pulando o que já se sabe:
1. **O produto e quem usa:** o que a aplicação faz, quem usa, em que contexto (escritório em tela grande, campo no celular, uso intenso diário ou esporádico).
2. **Personalidade:** três adjetivos para a sensação desejada, e um que ela **não** deve passar.
3. **Referências:** convide a enviar imagens, sites ou produtos de que goste (e de que não goste). Leia conforme as regras transversais.
4. **Marca:** cores, fonte e logotipo já definidos, se houver.
5. **Densidade e modo escuro:** quanta informação por tela; se o modo escuro é obrigatório, opcional ou desnecessário.

Com isso, leia `direcao-visual.md` e proponha **2 ou 3 direções** contrastantes, cada uma com nome, a ideia em uma frase, os valores dos eixos principais (paleta, tipografia, raio, densidade, borda/sombra), onde ela brilha e o seu risco. Uma delas deve ser a mais segura e outra deliberadamente menos óbvia. O usuário escolhe, mistura ou pede ajustes.

Depois, com `componentes-base.md`, confirme o **escopo da fundação**: o núcleo obrigatório entra sempre; pergunte pelos opcionais que o produto precisa.

### Modo novo componente
Siga `novo-componente.md`: problema e contexto de uso, se é composição/variante de algo existente ou peça nova, API, estados e casos de borda, teclado e leitores de tela, responsivo e conteúdo. Para componentes complexos (tabela editável, calendário, upload, editor, wizard, filtros combinados), **liste primeiro as decisões que precisam ser tomadas antes de desenhar**, cada uma com opções e uma recomendação, e resolva uma de cada vez. Se ainda assim for grande, proponha dividir em partes e começar pela menor que já entrega valor.

## 3. Proposta

Apresente no chat o que foi combinado:
- **Fundação:** a direção escolhida e os tokens (cores em OKLCH para claro e escuro, com contraste dos pares texto/fundo; família, escala e pesos tipográficos; espaçamento, raios, sombras), e a lista de componentes e páginas do showcase.
- **Novo componente:** nome e arquivo, API (tabela de propriedades), variantes e estados, comportamento de teclado/ARIA, exemplos que irão para a página do showcase.
- **Em aberto:** decisões pendentes e melhorias sugeridas que o usuário ainda não aceitou.

Pergunte com `AskUserQuestion`: **implementar agora**, **ajustar a proposta** (volte à etapa 2 no ponto necessário) ou **parar aqui** (entregue a proposta como resumo e encerre).

## 4. Implementação

Só com a aprovação da etapa 3. Lembre da branch se ainda estiver na `main`.

1. **Tokens:** em `packages/ui/src/styles/globals.css` (`@theme inline` + `:root`/`.dark`); fontes conforme o padrão do projeto. Nada de valor hardcoded nos componentes.
2. **Componentes:** parta do Shadcn (`make shadcn component=<nome>`) quando houver equivalente, ajuste imports para relativos e customize. Peças compostas vão em `components/common/`. Registre cada export em `packages/ui/src/index.ts`.
3. **Showcase:** uma página por componente (e uma por fundamento: cores, tipografia, espaçamento) em `apps/design-system/`, seguindo `anatomia-pagina.md`, com entrada na navegação.
4. **Testes:** testes de componente (Vitest + RTL, ver `docs/testing/frontend.md`) para comportamento e acessibilidade: estados, interação por teclado, `aria-*`, disabled. Escreva o teste antes do comportamento. Os marcadores `// spec:` entram na etapa 5, quando a spec existir.
5. **Revisão de detalhe:** passe cada página e componente pela lista "Detalhes que evidenciam descuido" de `direcao-visual.md` e compare com os vizinhos (padding, raio, alturas, foco, cores de texto). Corrija antes de seguir.
6. **Validação:** rode lint, build e testes do frontend pelos comandos do `AGENTS.md`/`Makefile`. Se possível, abra o showcase e confira claro/escuro e largura de celular.

Mudança grande (fundação inteira): divida em blocos (tokens → formulário → feedback → overlays), mostre o resultado de cada bloco e siga.

## 5. Docs e specs

Depois do código validado:
- **`docs/frontend/design-system.md`:** catálogo atualizado (componente, página do showcase, quando usar) e a direção visual com os tokens principais. Crie a partir de `../init/template/docs/frontend/design-system.md` se não existir, e garanta o link em `docs/frontend/frontend.md`.
- **`docs/frontend/styling.md`:** ajuste se houver regra nova de estilo (fontes, uso de sombra, densidade).
- **`specs/componentes/<componente>.md`:** um arquivo por componente, com o comportamento observável (variantes, estados, teclado, mensagens, limites), no padrão de `../spec/guia-de-escrita.md` e conferido contra `../shared/spec-lint.md`. Link a partir de `specs/specs.md` em **Transversais**.
- **Rastreabilidade:** adicione `// spec: specs/componentes/<componente>.md` nos testes (ver `../shared/rastreabilidade.md`).
- Rode `bash ${CLAUDE_PLUGIN_ROOT}/skills/shared/scripts/check-doc-links.sh` e `bash ${CLAUDE_PLUGIN_ROOT}/skills/shared/scripts/spec-coverage.sh specs/componentes/*.md` e corrija o que apontarem.

## 6. Fechamento

1. Resuma o que foi criado (tokens, componentes, páginas, docs, specs) e o que ficou em aberto.
2. Liste as melhorias sugeridas e não adotadas, para o usuário considerar depois.
3. Sugira a mensagem de commit e lembre que mudanças futuras de comportamento desses componentes seguem o fluxo `wbrain-std:spec` → `wbrain-std:tuning` (ou esta skill, para componentes novos).

## Limites

- Não grave nada antes da aprovação da etapa 3. Não crie branch, commit nem push.
- Atue só no frontend (`packages/ui`, `apps/design-system`, uso pontual nos apps quando combinado), em `docs/frontend/` e em `specs/componentes/` + link em `specs/specs.md`. Não altere backend nem specs de domínio.
- Não troque a stack (Shadcn, Tailwind, Remix Icon) sem o usuário pedir.
