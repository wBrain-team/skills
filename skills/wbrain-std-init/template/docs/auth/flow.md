# Fluxo de autenticação

[← Autenticação](auth.md)

```
1) Solicitar código                 2) Verificar código
───────────────────                 ────────────────────
POST /api/v1/auth/otp/request       POST /api/v1/auth/otp/verify
  { email }                           { email, code }
       ↓                                   ↓
  gera OTP (6 dígitos),               valida: existe, não expirou,
  grava HASH + expiração,             não usado, tentativas < máx
  envia e-mail via provedor                ↓
       ↓                              marca como usado, grava o refresh token (hash)
  202 Accepted (resposta              { data: { access_token, refresh_token, user } }
  genérica — não revela
  se o e-mail existe)

Refresh (access expirado)           Logout
─────────────────────────           ──────
POST /api/v1/auth/refresh           POST /api/v1/auth/logout
  { refresh_token }                   { refresh_token }
       ↓                                   ↓
  valida no banco (hash): existe,     revoga o refresh token (idempotente)
  não revogado, não expirado               ↓
       ↓                              204 No Content
  revoga o atual e emite novo par
  { data: { access_token, refresh_token } }
```

- **OTP** — código numérico de uso único, curta validade (`otp_expire_minutes`),
  **single-use** e com limite de tentativas (`otp_max_attempts`). Nunca trafega/persiste
  em texto puro: só o **hash** é gravado.
- **access_token** — JWT de curta duração (`access_token_expire_minutes`), no header
  `Authorization: Bearer <token>` em toda request autenticada. Não é persistido.
- **refresh_token** — token opaco de longa duração (`refresh_token_expire_days`),
  **persistido como hash** e **rotacionado** a cada uso; só serve para obter um novo par
  de tokens (ver [Refresh tokens](refresh-tokens.md)).
- **logout** — revoga o refresh token no servidor e limpa o estado de auth no cliente.

Todos os tempos vêm de `settings` (ver [Configuração e settings](../backend/config.md)).

---

**Veja também:** [OTP e JWT](otp.md) · [Refresh tokens](refresh-tokens.md) · [Auth no frontend](frontend.md)
