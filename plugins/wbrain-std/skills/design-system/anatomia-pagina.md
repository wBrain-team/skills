# Anatomia de uma página do showcase

Cada componente do `@design-system/ui` tem **uma página** no showcase (`apps/design-system/`), sempre nesta ordem:

1. **Título** — o nome do componente.
2. **Descrição** — um parágrafo: o que é, quando usar e quando **não** usar (indicando a alternativa).
3. **Referência de código** — nome do componente/classe exportado e o import:
   ```tsx
   import { Button } from "@design-system/ui"
   ```
   com o caminho do arquivo-fonte (ex.: `packages/ui/src/components/ui/button.tsx`).
4. **Tabela de propriedades** — colunas: Propriedade · Tipo · Padrão · Descrição. Inclua props herdadas relevantes (ex.: atributos nativos de `<button>`) em uma linha de nota.
5. **Exemplos** — uma seção por eixo de configuração, cada exemplo com a prévia renderizada e o código ao lado ou abaixo:
   - variantes;
   - tamanhos;
   - estados (default, focus, disabled, erro, loading);
   - composições comuns (com ícone, em formulário, em grupo);
   - casos de borda (texto longo, vazio).
6. **Uso e acessibilidade** — lista curta de **faça / não faça** e o comportamento de teclado.

Páginas de fundamentos (cores, tipografia, espaçamento) seguem os itens 1, 2, 5 e 6, mostrando os tokens com nome e valor.

Regras:
- Exemplos usam textos realistas do domínio do produto, não "Lorem ipsum".
- Toda página funciona em claro e escuro e em largura de celular.
- A navegação do showcase agrupa as páginas (Fundamentos, Ações, Formulário, Feedback, Sobreposição, Dados) e cada página nova entra no grupo certo.
