# Direção visual

Repertório para propor um visual com identidade. Use para montar as 2 ou 3 direções da etapa 2 e para justificar escolhas.

## Eixos de decisão

Uma direção é um conjunto coerente de escolhas nestes eixos. Mude poucos eixos com intenção, em vez de muitos ao acaso.

| Eixo | Extremos | Perguntas que decidem |
|---|---|---|
| Densidade | arejado ↔ compacto | Quanta informação por tela? Uso diário intenso pede compacto. |
| Contraste | suave ↔ alto | Ambiente de uso, idade do público, quantidade de dados. |
| Temperatura | fria ↔ quente | Neutros puxados para azul, para areia/oliva ou neutros puros? |
| Cor de marca | contida ↔ expansiva | A cor só marca ação primária ou ocupa superfícies? |
| Raio | reto (0–2px) ↔ arredondado (12px+) | Técnico e preciso ou acolhedor e casual? |
| Profundidade | bordas ↔ sombras | Hierarquia por linha, por camada ou por cor de fundo? |
| Tipografia | uma família ↔ par contrastante | Serifa nos títulos? Mono para números e códigos? |
| Escala | plana ↔ dramática | Títulos próximos do corpo ou bem maiores? |
| Movimento | nenhum ↔ expressivo | Transições só funcionais ou parte da personalidade? Respeite `prefers-reduced-motion`. |

## Direções de partida

Pontos de partida, não modelos fechados. Adapte à marca e ao público.

- **Ferramenta precisa** — compacto, neutros frios, raio 4px, bordas finas no lugar de sombras, sans grotesca + mono para números tabulares. Para back-office, dados, operações.
- **Editorial** — arejado, serifa nos títulos com sans no corpo, escala dramática, cor de marca contida, fundos levemente quentes. Para conteúdo, produtos premium, institucional moderno.
- **Acolhedor** — raio generoso, neutros quentes, cores de apoio saturadas em áreas pequenas, sombras curtas e nítidas. Para consumidor final, saúde, educação.
- **Brutalista contido** — raio 0, bordas de 1–2px em contraste alto, uma cor de acento forte, tipografia grande e pesada, sem sombras. Para marcas jovens e produtos que querem se destacar.
- **Institucional sóbrio** — contraste alto, paleta curta, raio 6px, tipografia de excelente legibilidade, hierarquia por peso. Para governo, finanças, jurídico.
- **Superfícies tonais** — hierarquia por camadas de fundo do mesmo matiz (sem bordas nem sombras pesadas), cor de marca tingindo os neutros. Para apps de uso contínuo que precisam de calma visual.

## "Cara de IA": escolha consciente, não defeito

**Nenhuma estética é proibida.** Se o tutor pedir um visual que lembre os produtos gerados por IA (gradientes suaves, cards arredondados, Inter, muito respiro), isso é uma direção legítima: siga com capricho. O problema não está nos elementos, e sim em **dois vícios do agente**:

1. **Padrão no piloto automático:** usar o default (do Shadcn, do Tailwind, do "app SaaS genérico") porque é o caminho mais curto, sem ter decidido isso com o tutor.
2. **Descuido nos detalhes:** alinhamentos, espaçamentos, raios e pesos escolhidos tela a tela, sem sistema. O resultado parece "quase certo", e é esse "quase" que denuncia a falta de cuidado.

Um projeto cuidadoso se reconhece pela **consistência**: as mesmas decisões repetidas em toda parte, de propósito. O agente tem plena capacidade de fazer isso. Ele precisa decidir de verdade e manter a disciplina.

### Padrões de piloto automático

Use só quando forem uma escolha, e diga por que servem ao produto:

- Gradiente roxo/azul em hero, botões ou fundos; "glow" e vidro fosco como decoração.
- Primária = azul ou violeta padrão do Shadcn; neutros cinza puros, sem nenhum matiz ligado à marca.
- Inter ou fonte do sistema em tudo, só com pesos 400 e 600; títulos pouco maiores que o corpo.
- `rounded-xl`/`rounded-2xl` e sombra grande e difusa em todo container.
- Tudo dentro de um card, inclusive cards dentro de cards; a página vira uma grade de caixas iguais.
- Ícone colorido em círculo pastel acima de cada título; três colunas de "features" com ícone + título + frase.
- Badge "Novo" ou "Beta", estrelinhas ✨ e emojis como ícones.
- Layout de landing page (hero centralizado, CTA duplo) aplicado a telas de sistema.
- Textos genéricos ("Lorem", "Acme", "Gerencie tudo em um só lugar") no lugar do conteúdo real do produto.

### Detalhes que evidenciam descuido

É aqui que mais se nota a diferença. Revise cada página e componente com esta lista:

**Espaçamento e ritmo**
- Valores avulsos (`p-[13px]`, `mt-7` numa tela e `mt-6` na vizinha) em vez da escala definida.
- Espaçamento igual em tudo: itens relacionados deveriam ficar mais próximos entre si do que de outros grupos (proximidade). Seções sem respiro maior que o espaço interno dos grupos.
- Padding interno de card, dialog e sheet diferente entre componentes equivalentes.
- Padding horizontal e vertical do botão sem relação com a altura do campo ao lado: botão e input lado a lado com alturas diferentes.

**Alinhamento**
- Elementos que "quase" alinham: título do card a 24px da borda e conteúdo a 20px; ícone 1px fora do eixo do texto.
- Ícone e texto sem alinhamento óptico (ícone parece alto ou baixo; tamanho do ícone desproporcional à fonte).
- Números de tabela alinhados à esquerda e sem dígitos tabulares (`tabular-nums`); colunas de valor sem alinhamento à direita.
- Rótulos de formulário com larguras e posições diferentes entre telas.

**Raios, bordas e sombras**
- Raio do elemento interno igual ao do externo: o interno deve ser menor (raio externo − padding) para as curvas ficarem concêntricas.
- Mistura sem regra de borda + sombra + fundo para indicar a mesma coisa (elevação).
- Bordas de espessuras ou tons diferentes para a mesma função; divisórias onde o espaçamento já separaria.
- Sombras que não seguem uma fonte de luz coerente nem uma escala de elevação.

**Tipografia**
- Tamanhos fora da escala; muitos tamanhos parecidos (13, 14, 15px) brigando entre si.
- Hierarquia feita só com tamanho, sem peso, cor ou espaçamento.
- Linhas longas demais (mais de ~75 caracteres) em texto corrido; altura de linha igual para título e corpo.
- Caixa alta sem aumento de espaçamento entre letras; mistura de "Title Case" e "Frase" em botões e títulos.

**Cor**
- Cinzas de texto diferentes para a mesma função (`text-gray-500` aqui, `text-muted-foreground` ali).
- Cor de marca usada em tudo, perdendo o papel de sinalizar a ação principal.
- Cores semânticas (erro, sucesso) com saturação ou luminosidade incoerentes entre si; modo escuro só invertido.

**Estados e interação**
- Hover existe e focus não; foco com o outline padrão do navegador em alguns componentes e anel customizado em outros.
- Disabled só com opacidade, ilegível; loading que muda a largura do botão; nenhum estado vazio ou de erro desenhado.
- Transições com durações e curvas diferentes em cada componente.

**Conteúdo e composição**
- Tela que não considera texto longo, nome sem foto, lista vazia ou número grande, e quebra com dados reais.
- Ícones de estilos misturados (linha e preenchido) na mesma área.
- Simetria forçada: tudo centralizado e em grades iguais, mesmo quando o conteúdo tem pesos diferentes.

### Como o agente evita os vícios

- **Decida antes, aplique sempre:** os tokens (espaçamento, raios, elevação, tipografia, duração de animação) saem da etapa 3. Na implementação, só valores desses tokens; um valor fora da escala exige motivo explícito.
- **Regras derivadas, não números soltos:** registre em `docs/frontend/design-system.md` regras como "raio interno = raio externo − padding", "campos e botões compartilham as alturas `sm`/`md`/`lg`" e "elevação: borda em superfícies, sombra só em overlays".
- **Revisão de detalhe por página:** antes de dar uma página ou componente por pronto, passe a lista acima e compare com os componentes vizinhos: mesmo padding, mesmo raio, mesmo foco.
- **Dados reais nos exemplos:** use o conteúdo do produto, com casos extremos, para revelar problemas de alinhamento e quebra.
- **Diga quando usou o padrão:** se a escolha foi o default, informe o tutor e ofereça a alternativa. Quando o tutor escolher a estética "de IA", execute-a com o mesmo rigor de detalhe.

## Como apresentar as direções

Para cada direção: **nome**, ideia em uma frase, valores dos eixos principais, uma amostra textual (ex.: um botão primário, um campo e um título descritos com tokens), **onde brilha** e **qual o risco**. Termine com a sua recomendação e o motivo, ligado ao que o usuário disse sobre público e personalidade.

## Checagens que valem para qualquer direção

- Contraste WCAG AA: 4.5:1 para texto, 3:1 para texto grande, bordas de campo e foco.
- Foco visível em todo elemento interativo, distinto do hover.
- Estado não depende só de cor (erro tem ícone ou texto).
- Alvos de toque de pelo menos 40px em telas de toque.
- Modo escuro não é inversão: ajuste saturação e elevação.
