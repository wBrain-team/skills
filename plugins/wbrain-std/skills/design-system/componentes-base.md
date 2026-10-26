# Componentes da fundação

O que entra na fundação do design system. O **núcleo** entra sempre; os **opcionais** entram se o produto precisar (pergunte).

## Fundamentos (páginas sem componente React próprio)

| Página | Conteúdo |
|---|---|
| Cores | Paleta de marca, neutros, semânticas (sucesso, alerta, erro, info), tokens de superfície, texto e borda; claro e escuro; contraste de cada par texto/fundo. |
| Tipografia | Famílias, escala (do `xs` ao título de página), pesos, alturas de linha; exemplo de hierarquia real (título, subtítulo, corpo, legenda). |
| Espaçamento, raio e elevação | Escala de espaçamento, raios, sombras ou camadas de superfície, foco. |
| Ícones | Tamanhos padrão e uso de Remix Icon (linha vs preenchido). |

## Núcleo

| Componente | Base Shadcn | Variantes / estados obrigatórios |
|---|---|---|
| Button | `button` | primária, secundária, outline, ghost, destrutiva, link; tamanhos; com ícone; só ícone (com `aria-label`); loading; disabled |
| Input | `input` | padrão, com ícone/prefixo, erro, disabled, readonly |
| Textarea | `textarea` | padrão, erro, contador de caracteres |
| Label + campo + mensagem | `form`, `label` | obrigatório, ajuda, erro |
| Select | `select` | padrão, placeholder, erro, disabled, grupos |
| Combobox | `command` + `popover` | busca, vazio, carregando, múltipla seleção |
| Checkbox | `checkbox` | marcado, indeterminado, disabled, com descrição |
| Radio | `radio-group` | vertical, horizontal, com descrição, disabled |
| Switch | `switch` | ligado, desligado, disabled, com rótulo |
| Badge | `badge` | semânticas e neutra |
| Tooltip | `tooltip` | posições; atraso; acessível por foco |
| Card | `card` | com cabeçalho, ações, conteúdo |
| Dialog | `dialog`, `alert-dialog` | formulário, confirmação destrutiva |
| Toast | `sonner` | sucesso, erro, com ação |

## Opcionais comuns

Tabs, Accordion, Dropdown menu, Date picker, Slider, Avatar, Skeleton, Progress, Breadcrumb, Pagination, Sheet/Drawer, Empty state, File upload.

## Estados que todo componente interativo cobre

default · hover · focus-visible · active · disabled · erro (quando aplicável) · loading (quando aplicável) · claro e escuro.
