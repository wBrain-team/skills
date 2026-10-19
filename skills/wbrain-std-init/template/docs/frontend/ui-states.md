# Estados de UI e notificações

[← Frontend](frontend.md)

## Estados de UI — carregando / erro / vazio

Toda tela que busca dados trata explicitamente os **três estados**. Nunca renderize uma
lista assumindo que os dados já chegaram.

- **Carregando** — skeleton (preferível) ou spinner enquanto `loading` do `useListData`
  é `true`. Mantém o layout estável (sem "pulo").
- **Erro** — o `useListData` já notifica via `toast` (`getApiErrorMessage`); para erro
  bloqueante de tela, mostre um estado de erro com ação de "tentar novamente".
- **Vazio** — use o `emptyState` do `DataList` (mensagem + CTA quando fizer sentido).
  Diferencie "vazio de verdade" de "ainda carregando".

```tsx
const { t } = useTranslation()
const { data: users = [], loading } = useListData(() => usersService.listAll(), [], {
  errorMessage: t("users.errors.load"),
})

if (loading) return <DataListSkeleton rows={5} />

<DataList
  columns={columns}
  data={users}
  keyExtractor={(u) => u.id}
  emptyState={<EmptyState title={t("users.empty.title")} description={t("users.empty.description")} />}
/>
```

## Notificações e erros de API

Erros da API seguem o contrato `{"error": {code, message}}` (ver
[Contrato da API](../backend/api-contract.md)). Centralize a extração em `getApiErrorMessage`
(`lib/errors.ts`) e notifique com `toast`.

```ts
// src/lib/errors.ts
import i18n from "@/lib/i18n"

const t = i18n.t.bind(i18n)  // fora de componentes, usa a instância do i18n

export function getApiErrorMessage(error: unknown): string {
  const apiError = (error as AxiosError<{ error?: { code?: string; message?: string } }>)
    ?.response?.data?.error
  // traduz pelo code estável; cai na message do servidor; por fim, genérica
  if (apiError?.code) return t(`errors.${apiError.code}`, { defaultValue: apiError.message ?? "" })
  return apiError?.message ?? t("errors.GENERIC")
}
```

**Regras:**
- **Erros de campo** (ex.: e-mail já cadastrado) vão para o formulário via
  `form.setError("field", { message })`, não para o toast.
- **Erros de operação** (falha ao salvar/listar) vão para o `toast`.
- Sucesso relevante (criou/excluiu) também usa `toast` curto e objetivo.

---

**Veja também:** [DataList](data-list.md) · [i18n](i18n.md)
