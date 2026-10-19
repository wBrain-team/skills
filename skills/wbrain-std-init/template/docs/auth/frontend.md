# Auth no frontend

[← Autenticação](auth.md)

## Fluxo de login em 2 passos

A tela de login tem dois estados: **(1)** informar o e-mail → dispara `otp/request`;
**(2)** informar o código recebido → `otp/verify` retorna `{access_token, refresh_token, user}`
e popula o store. O exemplo de formulário (React Hook Form + Zod) está em
[Formulários](../frontend/forms.md).

```ts
// services/auth.service.ts
export interface AuthResult {
  access_token: string
  refresh_token: string
  user: User
}

export const authService = {
  requestOtp: (email: string) => api.post("/api/v1/auth/otp/request", { email }),
  verifyOtp: (email: string, code: string): Promise<AuthResult> =>
    api.post("/api/v1/auth/otp/verify", { email, code }).then((r) => r.data.data),
  logout: (refresh_token: string) => api.post("/api/v1/auth/logout", { refresh_token }),
}

// após verificar o código
const result = await authService.verifyOtp(email, code)
useAuthStore.getState().login({
  user: result.user,
  accessToken: result.access_token,
  refreshToken: result.refresh_token,
})
```

## Logout

O logout revoga o refresh token no servidor e **sempre** limpa o estado local, mesmo que
a chamada falhe (rede, token já inválido):

```ts
async function signOut() {
  const { refreshToken, logout } = useAuthStore.getState()
  try {
    if (refreshToken) await authService.logout(refreshToken)
  } finally {
    logout()
  }
}
```

## Auth store (`useAuthStore`)

O store Zustand é a **única fonte de verdade** para autenticação: tokens, usuário e
`isAuthenticated`. Persistido em `localStorage` (ver shape e regras em
[Estado global](../frontend/state.md)).

```ts
useAuthStore.getState().setTokens(accessToken, refreshToken)  // após refresh (rotação)
useAuthStore.getState().logout()                              // limpa o estado de auth
```

## Interceptor 401 → refresh → logout

O interceptor de resposta do axios tenta um refresh único ao receber 401. Como o refresh
token é **rotacionado**, a resposta traz um novo par e o store substitui os dois
(`setTokens`). Se o refresh falhar, faz `logout()` e redireciona para `/login` (ver
[Comunicação com a API](../frontend/api-client.md)).

> **Nunca** use `localStorage.clear()` no interceptor — isso apaga dados de outros
> módulos. Use sempre `logout()` do store (limpa só o estado de auth).

## Guards de rota

Toda rota usa um dos guards definidos em `App.tsx`:

| Guard | Uso | Comportamento |
|---|---|---|
| `RequireAuth` | Rotas protegidas | Redireciona para `/login` se não autenticado |
| `PublicRoute` | Rotas públicas (`/login`) | Redireciona para `/dashboard` se já autenticado |
| `DefaultRedirect` | Raiz `/` e wildcard `*` | `/dashboard` se autenticado, `/login` se não |

```tsx
<Route path="/settings" element={<RequireAuth><SettingsPage /></RequireAuth>} />
<Route path="/register" element={<PublicRoute><RegisterPage /></PublicRoute>} />
```

O guard lê `isAuthenticated` do `useAuthStore` — a fonte única de verdade.

> **Nunca** use `<Navigate to="/login" replace />` diretamente no wildcard — isso quebra a
> navegação de usuários autenticados. Use `DefaultRedirect`.

---

**Veja também:** [Estado global](../frontend/state.md) · [Cliente da API](../frontend/api-client.md) · [Formulários](../frontend/forms.md)
