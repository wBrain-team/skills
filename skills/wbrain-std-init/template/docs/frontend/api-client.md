# Comunicação com a API

[← Frontend](frontend.md)

## Formato dos dados — snake_case

A API usa **snake_case** em todo JSON, nas duas direções (ver
[Contrato da API](../backend/api-contract.md#formato-dos-campos--snake_case)). O frontend
**não converte** case: os tipos que representam dados da API usam snake_case, e o payload
enviado já sai nesse formato.

- Interfaces/tipos de entidades e payloads da API: `is_active`, `page_size`, `created_at`.
- Variáveis, funções e estado local do frontend seguem camelCase normalmente.
- Configure a regra de nomenclatura do ESLint (`@typescript-eslint/naming-convention`)
  para aceitar snake_case em propriedades de tipos e objetos.

## Axios — instância configurada

Crie uma instância centralizada em `src/lib/axios.ts`. Nunca importe `axios` diretamente em components ou services — sempre use esta instância.

```typescript
// src/lib/axios.ts

import axios from "axios"
import { useAuthStore } from "@/store/auth.store"

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  headers: { "Content-Type": "application/json" },
})

// injeta o token em toda requisição
api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().accessToken
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// 401 → um único refresh (com rotação); se falhar, logout pelo store
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const original = error.config

    if (error.response?.status === 401 && !original._retry) {
      original._retry = true
      try {
        const { refreshToken } = useAuthStore.getState()
        const { data } = await axios.post(
          `${import.meta.env.VITE_API_URL}/api/v1/auth/refresh`,
          { refresh_token: refreshToken }
        )
        // o refresh é rotacionado: substitua os DOIS tokens
        useAuthStore.getState().setTokens(data.data.access_token, data.data.refresh_token)
        original.headers.Authorization = `Bearer ${data.data.access_token}`
        return api(original)
      } catch {
        useAuthStore.getState().logout() // nunca localStorage.clear(): apagaria outros módulos
        window.location.href = "/login"
      }
    }

    return Promise.reject(error)
  }
)
```

## Services — tipagem e organização

Cada domínio tem seu próprio service em `src/services/`. Os services encapsulam as chamadas
HTTP e tipam as respostas — components nunca chamam `api` diretamente. Os envelopes do
contrato ficam tipados em `src/types/api.ts`:

```typescript
// src/types/api.ts
export interface PageMeta {
  page: number
  page_size: number
  total: number
  total_pages: number
}

export interface Paginated<T> {
  data: T[]
  pagination: PageMeta
}
```

Regra de retorno: listagens paginadas devolvem o `Paginated<T>` inteiro (a tela usa
`data` e `pagination`); recurso único e listas sem paginação devolvem o conteúdo de `data`.

```typescript
// src/services/users.service.ts

import { api } from "@/lib/axios"
import type { Paginated } from "@/types/api"

export interface User {
  id: string
  name: string
  email: string
  is_active: boolean
}

export interface UserListParams {
  page?: number
  page_size?: number
  search?: string
}

export const usersService = {
  async list(params: UserListParams = {}): Promise<Paginated<User>> {
    const { data } = await api.get("/api/v1/users", { params })
    return data
  },

  async listAll(): Promise<User[]> {
    const { data } = await api.get("/api/v1/users/all")  // envelope sem paginação
    return data.data
  },

  async getById(id: string): Promise<User> {
    const { data } = await api.get(`/api/v1/users/${id}`)
    return data.data
  },

  async create(payload: { name: string; email: string; is_active: boolean }): Promise<User> {
    const { data } = await api.post("/api/v1/users", payload)
    return data.data
  },
}
```

---

**Veja também:** [Auth no frontend](../auth/frontend.md) · [Contrato da API](../backend/api-contract.md) · [Estados de UI e erros](ui-states.md)
