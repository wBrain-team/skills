---
name: design-system
description: Conduz a criação ou a evolução do design system do projeto (`@design-system/ui` + showcase). Sem design system ativo, entrevista o usuário (aceita imagens de referência), propõe direções visuais com personalidade, fugindo do visual genérico, e monta a fundação (tokens, cores, tipografia e componentes básicos). Com o design system existente, ajuda a pensar um componente novo e antecipa as decisões que ele exige. Apresenta o combinado e, com o consentimento do usuário, implementa o código, uma página de showcase por componente, e depois atualiza `docs/` e `snaps/`. Use apenas quando o usuário pedir explicitamente ajuda com o design system ou com um componente de interface.
disable-model-invocation: true
---

# wbrain-std:design-system

Skill da série **wbrain-std** — STD = **Source-of-Truth-Driven**, a técnica da wbrain para desenvolvimento com IA: o `snaps/` é a fonte da verdade, e a implementação avança em TDD estrito a partir dele.

A `wbrain-std:init` cria projetos novos, a `wbrain-std:onboard` traz projetos existentes para o padrão, a `wbrain-std:snaps` ajuda a escrever snaps e a `wbrain-std:tuning` implementa mudanças a partir delas. Esta skill é a **parceira de design de interface**: monta a fundação do design system quando não há nenhum e ajuda a desenhar componentes novos quando ele já existe. O objetivo é sempre uma interface **bonita, mas antes de tudo usável**: clara, acessível e adequada a quem vai usá-la.

Siga as etapas **na ordem**. Fale com o usuário em pt-BR. Leia `AGENTS.md` antes de começar.

## Referências

Caminhos relativos à pasta desta skill (`${CLAUDE_PLUGIN_ROOT}/skills/design-system/`):
- `direcao-visual.md`: eixos de decisão visual, direções de partida e sinais de "cara de IA" a evitar.
- `componentes-base.md`: o que compõe a fundação e os estados obrigatórios de cada componente.
- `novo-componente.md`: roteiro para pensar um componente novo e levantar decisões antecipadas.
- `anatomia-pagina.md`: o contrato de cada página do showcase.
- `../shared/subagentes.md`, `../shared/snaps-lint.md`, `../shared/rastreabilidade.md`: regras comuns do kit.
- `../shared/tdd-e-cobertura.md`: TDD estrito e cobertura, com `docs/` como lei (etapas 4 e 5).
- `../shared/ambiente-docker.md`: verificação e montagem do ambiente Docker (guarda 4), e padrão de `node_modules` em volume.
- `../snaps/guia-de-escrita.md`: como escrever os snaps de componente.

## Regras transversais (valem em todas as etapas)

### Código só depois do consentimento
- Até a etapa 4, **nada é gravado** no projeto. Propostas de tokens, API e layout aparecem **no chat**. Única exceção: o ambiente Docker, se o usuário aprovar montá-lo (guarda 4).
- A implementação só começa quando o usuário aprovar a proposta da etapa 3. Branch só com o ok do usuário (etapa 0); não faça commit nem push.
- Decisões que só o usuário pode tomar (marca, público, prioridades) voltam como pergunta. Não as invente; proponha opções.

### Condução da conversa
- **Entrevista objetiva e enxuta:** uma pergunta por vez, só o que muda o resultado. Pule o que o projeto, as imagens ou respostas anteriores já responderam.
- Pergunte **a partir do que foi descoberto**: "Vi `--primary` com o azul padrão do Shadcn em `globals.css`. A marca tem uma cor própria?".
- **Fallback de baixa colaboração:** se o usuário der respostas curtas ou vagas ("não sei", "tanto faz", "algo bonito") em duas perguntas, ou disser que tem dificuldade de explicar o que quer, passe a usar `AskUserQuestion` com opções prontas e concretas (use `preview` para comparar paletas, escalas ou layouts em ASCII). A opção recomendada vem primeiro, marcada "(Recomendado)". Se ele voltar a responder com riqueza, retome as perguntas abertas.
- **Imagens de referência:** quando o usuário enviar imagens, descreva o que leu delas (paleta aproximada, família e peso tipográfico, raio, densidade, uso de borda e sombra, tom geral) e peça confirmação antes de usar. Diga o que é inferência.
- **Seja propositivo:** não se limite ao que foi pedido. Aponte problemas de usabilidade e acessibilidade, sugira melhorias e, ao propor visual, ofereça **pelo menos uma alternativa fora do óbvio** (ver `direcao-visual.md`). O padrão às vezes basta; diga quando for o caso, mas mostre o outro caminho. Nenhuma estética é proibida, inclusive a "cara de IA", se o tutor a escolher. O que se evita é o padrão no piloto automático e o descuido com detalhes: alinhamento, espaçamento, raios e consistência entre componentes.

### Padrões do projeto
**Como desenvolver** (TDD, testes, cobertura) é a lei de `docs/`: siga `../shared/tdd-e-cobertura.md` com rigor, sem afrouxar o que `docs/guidelines/tdd.md` e `docs/testing/` exigem. Siga também `docs/frontend/styling.md`, `structure.md`, `design-system.md` (se existir) e `docs/guidelines/accessibility.md`: Shadcn como base modificável, Tailwind v4, tokens OKLCH em `globals.css`, ícones Remix Icon, textos via `t()`, exports em `packages/ui/src/index.ts`. Use subagentes conforme `../shared/subagentes.md`.

## 0. Guardas (orientam, não bloqueiam)

Rode `git branch --show-current` e `git status --short`.

1. **Pasta vazia ou projeto fora do padrão** (sem `AGENTS.md`/`docs/`): sugira `wbrain-std:init` (projeto novo) ou `wbrain-std:onboard` (existente) e encerre se o usuário concordar.
2. **Projeto sem frontend** (sem `src-frontend/` nem `docs/frontend/`, ou `docs/` declara que o projeto é só backend, como um microsserviço ou uma API): **recuse e encerre**. Explique que a skill existe para o design system de uma interface e que o projeto não tem uma. Não siga com a entrevista, nem para "só definir a direção visual". Se o projeto passar a ter frontend, ele deve ser adicionado primeiro (e documentado em `docs/frontend/`); depois a skill pode ser invocada de novo.
3. **Branch `main`/`master` ou HEAD destacado:** nada é produzido nela. Proponha com `AskUserQuestion` um nome de branch no padrão de `docs/guidelines/git.md` (ex.: `feat/design-system-base`) e **crie a branch só com o ok** do usuário. Sem ok, a conversa segue (até a etapa 4 nada é gravado); a branch volta a ser pedida antes da implementação.
4. **Ambiente Docker:** siga `../shared/ambiente-docker.md` (verificação, proposta de montagem e `node_modules` em volume) para o frontend: `frontend`, `nginx`, `Makefile` e o showcase acessível. Ambiente completo → siga. Ausente ou incompleto → proponha montá-lo **antes de qualquer código do design system**; ele só é criado com o ok do usuário e fora da `main` (guarda 3). Sem ok, a entrevista e a proposta seguem, mas a implementação (etapa 4) só começa com o ambiente de pé.

## 1. Diagnóstico

Com um subagente, levante: `globals.css` (tokens ainda são os padrões do Shadcn?), componentes em `packages/ui/src/components/`, exports de `index.ts`, páginas existentes em `apps/design-system/`, `docs/frontend/design-system.md` e `snaps/componentes/`.

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

Só com a aprovação da etapa 3 e fora da `main`: se ainda estiver nela, peça a branch de novo (etapa 0); sem ela, entregue a proposta como resumo e encerre.

0. **Ambiente:** confirme que o ambiente Docker está de pé (guarda 4). Toda instalação, `make shadcn`, lint, build e teste roda pelo container; nada de `npm` no host.
1. **Regras de teste:** leia `docs/guidelines/tdd.md` e `docs/testing/` (de `frontend.md` em especial) e anote o comando de teste pontual, o de cobertura e os mínimos (`../shared/tdd-e-cobertura.md`, seção 1).
2. **Tokens:** em `packages/ui/src/styles/globals.css` (`@theme inline` + `:root`/`.dark`); fontes conforme o padrão do projeto. Nada de valor hardcoded nos componentes. Confira o contraste dos pares texto/fundo.
3. **Componentes, um por vez, em TDD** (`../shared/tdd-e-cobertura.md`, seção 2): (a) **teste primeiro** (Vitest + RTL, `docs/testing/frontend.md`): estados, interação por teclado, `aria-*`, disabled, variantes; (b) rode e **confirme o vermelho**; (c) só então gere (`make shadcn component=<nome>`, quando houver equivalente) e implemente: imports relativos, customização, exports em `packages/ui/src/index.ts`; peças compostas em `components/common/`; (d) verde; (e) refactor. Nunca crie o arquivo do componente antes do arquivo de teste.
4. **Showcase:** uma página por componente (e uma por fundamento) em `apps/design-system/`, seguindo `anatomia-pagina.md`, com entrada na navegação. Também em TDD: teste de renderização da página antes dela.
5. **Revisão de detalhe:** passe cada página e componente pela lista "Detalhes que evidenciam descuido" de `direcao-visual.md` e compare com os vizinhos (padding, raio, alturas, foco, cores de texto). Corrija antes de seguir.
6. **Validação:** rode lint, build e a suíte do frontend pelos comandos do `AGENTS.md`/`Makefile`, e depois a **cobertura** (`../shared/tdd-e-cobertura.md`, seção 3). Abaixo do mínimo dos `docs/` → escreva os testes que faltam. Se os `docs/` não definem comando ou mínimo para o frontend, reporte o medido e proponha o texto para `docs/testing/`. Se possível, abra o showcase e confira claro/escuro e largura de celular.

Mudança grande (fundação inteira): divida em blocos (tokens → formulário → feedback → overlays), mostre o resultado de cada bloco e siga.

## 5. Docs e snaps

Depois do código validado:
- **`docs/frontend/design-system.md`:** catálogo atualizado (componente, página do showcase, quando usar) e a direção visual com os tokens principais. Crie a partir de `../init/template/docs/frontend/design-system.md` se não existir, e garanta o link em `docs/frontend/frontend.md`.
- **`docs/frontend/styling.md`:** ajuste se houver regra nova de estilo (fontes, uso de sombra, densidade).
- **`snaps/componentes/<componente>.md`:** um arquivo por componente, com o comportamento observável (variantes, estados, teclado, mensagens, limites), no padrão de `../snaps/guia-de-escrita.md` e conferido contra `../shared/snaps-lint.md`. Link a partir de `snaps/snaps.md` em **Transversais**.
- **Rastreabilidade:** adicione `// snap: snaps/componentes/<componente>.md` nos testes (ver `../shared/rastreabilidade.md`).
- Rode `bash ${CLAUDE_PLUGIN_ROOT}/skills/shared/scripts/check-doc-links.sh` e `bash ${CLAUDE_PLUGIN_ROOT}/skills/shared/scripts/snaps-coverage.sh snaps/componentes/*.md` e corrija o que apontarem.

## 6. Fechamento

1. Resuma o que foi criado (tokens, componentes, páginas, docs, snaps) e o que ficou em aberto. Inclua a **evidência de TDD** (vermelho confirmado por componente) e os **números de cobertura** contra o mínimo (`../shared/tdd-e-cobertura.md`, seção 4).
2. Liste as melhorias sugeridas e não adotadas, para o usuário considerar depois.
3. Sugira a mensagem de commit e lembre que mudanças futuras de comportamento desses componentes seguem o fluxo `wbrain-std:snaps` → `wbrain-std:tuning` (ou esta skill, para componentes novos).

## Limites

- Não grave nada antes da aprovação da etapa 3. Branch só com o ok do usuário; não faça commit nem push.
- Atue só no frontend (`packages/ui`, `apps/design-system`, uso pontual nos apps quando combinado), em `docs/frontend/` e em `snaps/componentes/` + link em `snaps/snaps.md`. Não altere backend nem snaps de domínio. A exceção é o ambiente Docker (compose, Dockerfiles, Makefile, nginx, `.env.example`, `.gitignore`), só no escopo de `../shared/ambiente-docker.md` e com o ok do usuário; não toque em `deploy/`.
- Não troque a stack (Shadcn, Tailwind, Remix Icon) sem o usuário pedir.
- Nenhum arquivo de implementação (componente ou página) antes do seu teste, nem entrega sem a cobertura conferida.
