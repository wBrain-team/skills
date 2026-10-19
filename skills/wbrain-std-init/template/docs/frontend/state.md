# Estado global — Zustand

[← Frontend](frontend.md)

Use **Zustand** para estado compartilhado entre telas/componentes (auth, preferências,
caches leves). Estado puramente local de um componente fica em `useState`/`useReducer` —
não promova ao store o que só uma tela usa.

```ts
// store/auth.store.ts
import { create } from "zustand"
import { persist } from "zustand/middleware"

interface AuthState {
  user: User | null
  accessToken: string | null
  refreshToken: string | null
  isAuthenticated: boolean
  login: (p: { user: User; accessToken: string; refreshToken: string }) => void
  setTokens: (accessToken: string, refreshToken: string) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      accessToken: null,
      refreshToken: null,
      isAuthenticated: false,
      login: ({ user, accessToken, refreshToken }) =>
        set({ user, accessToken, refreshToken, isAuthenticated: true }),
      setTokens: (accessToken, refreshToken) => set({ accessToken, refreshToken }),
      logout: () => set({ user: null, accessToken: null, refreshToken: null, isAuthenticated: false }),
    }),
    { name: "auth" } // chave no localStorage
  )
)
```

**Regras:**
- Em componentes, selecione fatias para evitar re-render desnecessário:
  `const user = useAuthStore((s) => s.user)`.
- Fora de componentes (interceptors, helpers), use `useAuthStore.getState()`.
- O estado interno do store usa camelCase; a conversão para/da API (snake_case) acontece
  só no ponto de chamada (ex.: `login({ user, accessToken: r.access_token, ... })`).
- O `useAuthStore` é a fonte única de auth (ver [Auth no frontend](../auth/frontend.md)); nunca leia tokens
  direto do `localStorage` em telas.

---

**Veja também:** [Auth no frontend](../auth/frontend.md)
