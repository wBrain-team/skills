# Design system — `@design-system/ui`

[← Frontend](frontend.md)

O design system vive em `src-frontend/packages/ui` e tem um showcase em `apps/design-system`
(http://localhost:8085/). Para criar a fundação ou um componente novo, use a skill
`wbrain-std:design-system`.

## Direção visual

<!-- Preenchido pela skill design-system: nome da direção, ideia em uma frase e tokens principais. -->
Tokens padrão do Shadcn, ainda sem direção visual própria.

## Página do showcase

Todo componente exportado tem uma página no showcase, nesta ordem:

1. Título.
2. Descrição: o que é, quando usar e quando não usar.
3. Referência de código: nome exportado, import de `@design-system/ui` e arquivo-fonte.
4. Tabela de propriedades: Propriedade · Tipo · Padrão · Descrição.
5. Exemplos por variante, tamanho, estado, composição e caso de borda, com prévia e código.
6. Uso e acessibilidade: faça / não faça e comportamento de teclado.

Páginas funcionam em claro, escuro e largura de celular, com textos realistas do produto.

## Catálogo

| Componente | Página do showcase | Quando usar |
|---|---|---|

O comportamento de cada componente fica em `snaps/componentes/<componente>.md`.

---

**Veja também:** [Estilização](styling.md) · [Estrutura](structure.md) · [Acessibilidade](../guidelines/accessibility.md)
