# Utilitários compartilhados do app (`apps/web/src`)

[← Frontend](frontend.md)

Além do `@design-system/ui` (compartilhado entre apps), o app `web` mantém peças reutilizáveis
**locais**, em `apps/web/src`. Reaproveite-as antes de duplicar o padrão.

## Carregamento de listas — `useListData` (`hooks/useListData.ts`)

Encapsula o padrão repetido nas telas de listagem: dispara o `fetcher` quando as
dependências mudam, controla `loading`, descarta respostas obsoletas (flag `active`
no cleanup) e notifica erros via `toast` usando `getApiErrorMessage`.

```tsx
const { t } = useTranslation()
const { data: users = [], loading } = useListData(
  () => usersService.listAll(),
  [],
  { errorMessage: t("users.errors.load") }
)
```

Em listagens paginadas, o `fetcher` devolve o `Paginated<T>` inteiro (ver
[Services](api-client.md#services--tipagem-e-organização)) e a tela deriva os pedaços
(ver `AuditLogsListPage`):

```tsx
const { data: result, loading } = useListData(
  () => auditService.list({ page, page_size: PAGE_SIZE, search }),
  [page, search],
  { errorMessage: t("audit.errors.load") }
)
const logs = result?.data ?? []
const pagination = result?.pagination ?? makePaginationFallback(page, PAGE_SIZE)
```

## Opções assíncronas (seletores/filtros) — `useAsyncOptions` (`hooks/useAsyncOptions.ts`)

Para dados auxiliares carregados de forma silenciosa (opções de combobox/select), em
vez de repetir `service.listAll().then(setX).catch(() => undefined)` num `useEffect`:
dispara o `fetcher` quando `deps` muda, ignora respostas obsoletas, descarta erros sem
ruído e devolve o valor (iniciado com `fallback`). Use `enabled: false` para adiar a
busca (ex.: depende de permissão).

```tsx
const userOptions = useAsyncOptions(
  () => usersService.listAll().then((items) => items.map((u) => ({ id: u.id, name: u.name }))),
  [],
  { fallback: [] as { id: string; name: string }[] }
)
// só carrega quando há permissão:
const categories = useAsyncOptions(() => categoriesService.list(), [canEdit], {
  fallback: [] as CategoryOption[],
  enabled: canEdit,
})
```

## Paginação de fallback — `makePaginationFallback` (`lib/pagination.ts`)

`makePaginationFallback(page, pageSize)` devolve o `PageMeta` "vazio"
(`{ page, page_size, total: 0, total_pages: 0 }`) usado enquanto a primeira resposta
não chegou. Centraliza o objeto repetido em todas as telas de listagem — combine com
`useListData`: `const pagination = result?.pagination ?? makePaginationFallback(page, PAGE_SIZE)`.

## Validadores Zod compartilhados — `lib/schemas/common.ts`

Helpers para os padrões repetidos entre schemas de formulário:
`requiredString(message)` (`z.string().min(1, message)`) e
`requiredEmail(emptyMessage, invalidMessage)` (obrigatório + formato). As mensagens vêm
sempre do i18n — os schemas de domínio (`user.schema.ts`, `post.schema.ts`) são fábricas
que recebem o `t` (ver [Formulários](forms.md)).

## Rótulos de domínio — i18n + `lib/labels.ts`

Rótulos de valores de domínio são **chaves de tradução**, nunca mapas de texto fixo:
``t(`roles.${user.role}`)``, ``t(`audit.operations.${log.operation}`)``. O `lib/labels.ts`
guarda só o que não é texto e se repete entre telas — ex.: `operationVariant` (variante
do Badge de auditoria). Importe daqui em vez de redeclarar o `Record` em cada página.

## `components/common/`

Componentes reutilizáveis **deste app** (não promovidos ao `@design-system/ui`). Ex.:
`SectionTitle` (subtítulo de seção dos formulários, usado por `UserForm`).
Quando um componente passar a ser útil a outros apps, mova-o para `@design-system/ui`.

---

**Veja também:** [DataList](data-list.md) · [Estados de UI](ui-states.md)
