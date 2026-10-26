# Frontend

[← Índice](../docs.md)

React 19 + TypeScript + Vite, em monorepo com o design system `@design-system/ui`
(showcase em http://localhost:8085/).

## Regras obrigatórias

- Toda rota usa um dos guards `RequireAuth` / `PublicRoute` / `DefaultRedirect` — ver [Auth no frontend](../auth/frontend.md#guards-de-rota).
- `useAuthStore` é a única fonte de verdade de auth; no interceptor de 401 use `logout()`, nunca `localStorage.clear()` — ver [Auth no frontend](../auth/frontend.md#auth-store-useauthstore).
- Toda listagem usa `DataList` do `@design-system/ui` — ver [data-list.md](data-list.md).
- Dados da API em **snake_case**, lidos e enviados sem conversão — ver [api-client.md](api-client.md#formato-dos-dados--snake_case).
- Componentes do design system sempre importados de `@design-system/ui`.
- Ícones exclusivamente via `@remixicon/react`; nenhuma string visível hardcoded (use `t()`), inclusive mensagens do Zod.

## Guias

| Arquivo | Conteúdo |
|---|---|
| [structure.md](structure.md) | Monorepo, `@design-system/ui`, pastas de `apps/web/src` |
| [styling.md](styling.md) | Tailwind v4 + Shadcn/UI, organização de componentes |
| [design-system.md](design-system.md) | Direção visual, páginas do showcase e catálogo de componentes |
| [api-client.md](api-client.md) | snake_case, instância Axios, tipos `Paginated`/`PageMeta`, services por domínio |
| [shared-utilities.md](shared-utilities.md) | `useListData`, `useAsyncOptions`, paginação, Zod comum, rótulos |
| [data-list.md](data-list.md) | Listagens: larguras, truncamento, ordenação, mobile |
| [forms.md](forms.md) | React Hook Form + Zod |
| [form-design.md](form-design.md) | Seções, grade e controles de formulário |
| [page-layout.md](page-layout.md) | Largura das páginas, `PageHeader`, `FormFooter` |
| [state.md](state.md) | Zustand |
| [ui-states.md](ui-states.md) | Carregando / erro / vazio e notificações |
| [env-vars.md](env-vars.md) | Variáveis `VITE_*` |
| [i18n.md](i18n.md) | `react-i18next` |

---

**Veja também:** [Auth no frontend](../auth/frontend.md) · [Testes de frontend](../testing/frontend.md) · [Acessibilidade](../guidelines/accessibility.md)
