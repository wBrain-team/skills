# Listagens — `DataList` (`@design-system/ui`)

[← Frontend](frontend.md)

Toda listagem tabular usa o `DataList`. Veja a vitrine em **Design System → Dados e tabelas**.

## Larguras de coluna previsíveis (regra obrigatória)

O `DataList` usa **`table-layout: fixed`** por padrão: a largura das colunas **nunca
depende do conteúdo**. Isso elimina o "salto" de colunas ao paginar/ordenar/filtrar —
as informações ficam sempre na mesma posição, o que é essencial para usabilidade.

Modele cada tabela com dois tipos de coluna:

- **Fixa** — defina `width` (ex.: `"12rem"`). Use para conteúdo de tamanho previsível:
  datas, valores monetários, documentos, status/badges, tipos e ações.
- **Flexível** — **omita** `width`. Repartem proporcionalmente o espaço restante. Use
  para texto livre de comprimento variável (nome, e-mail). Tenha **pelo menos uma**
  coluna flexível para absorver a largura disponível.

Nunca dependa do conteúdo para dimensionar colunas. Se uma tabela "pula", falta `width`
nas colunas previsíveis e/ou uma coluna flexível.

## Truncamento e tooltip

Por padrão as células **truncam com reticências** (mantém a altura da linha estável). Para
expor o valor completo no hover:

- Sem `render`: o `title` é preenchido **automaticamente** com o valor textual.
- Com `render`: informe `title: (row) => string` para o tooltip do valor completo.
- `wrap: true` desliga o truncamento (permite múltiplas linhas) — use só para conteúdo
  composto que não deve ser cortado (ex.: rótulo com ícone + marcadores).

## Ordenação

Marque colunas ordenáveis com `sortable: true`. O estado é **controlado** (`sort` +
`onSortChange`); a página decide aplicar no servidor (listas paginadas) ou localmente
(ex.: listas pequenas já carregadas). **Defina uma ordenação padrão** no estado inicial
da página (ex.: usuários por `name` asc).

```tsx
const { t } = useTranslation()

const columns: DataListColumn<User>[] = [
  // Flexível (texto livre) → sem width, trunca com tooltip automático.
  { key: "name", header: t("users.fields.name"), primary: true, sortable: true },
  // Fixas → width previsível.
  { key: "email", header: t("users.fields.email"), width: "16rem", sortable: true,
    title: (u) => u.email },
  { key: "role", header: t("users.fields.role"), width: "9rem", sortable: true,
    render: (u) => t(`roles.${u.role}`) },
]

const [sort, setSort] = useState<SortState | null>({ key: "name", direction: "asc" })

<DataList columns={columns} data={items} keyExtractor={(u) => u.id}
  sort={sort} onSortChange={setSort} />
```

No mobile (`< md`) o `DataList` troca a tabela por cards — a regra de largura vale para a
tabela (desktop); os cards empilham os campos verticalmente, com o campo `primary` como
título e sem as colunas marcadas com `hideOnMobile: true`. Os dois layouts ficam no DOM e a
visibilidade é controlada só por CSS (sem JS de breakpoint). Ações por linha e estado vazio
entram via `renderActions={(item) => ...}` e `emptyState={...}`.

---

**Veja também:** [Estados de UI](ui-states.md) · [Testes de frontend](../testing/frontend.md)
