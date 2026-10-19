# Usuário atual, RBAC e regras de segurança

[← Autenticação](auth.md)

A dependency `get_current_user` (em `app/api/deps.py`) decodifica o token, carrega o
usuário e o injeta nos routers. O controle por papel é uma dependency derivada:

```python
# app/api/deps.py
def require_role(*roles: UserRole):
    async def _dep(user: User = Depends(get_current_user)) -> User:
        if user.role not in roles:
            raise ForbiddenError("Sem permissão para esta operação")
        return user
    return _dep

# rota restrita a administradores
@router.get("/api/v1/audit-logs")
async def list_audit_logs(user: User = Depends(require_role(UserRole.ADMIN))):
    ...
```

**Regras de segurança (backend):**
- O código OTP só existe **hasheado** no banco; **nunca** loggue nem retorne o código.
- `otp/request` responde **sempre** de forma genérica (202) — não revela se o e-mail
  está cadastrado (evita enumeração de usuários).
- OTP é **single-use**, expira em `otp_expire_minutes` e respeita `otp_max_attempts`.
- **Rate limit** em `otp/request` por e-mail/IP (evita flood e abuso de envio de e-mail).
- Services **nunca** levantam `HTTPException` — lançam `UnauthorizedError` (401) /
  `ForbiddenError` (403), convertidas pelo handler global (ver [Exceções de domínio](../backend/exceptions.md)).
- **Papel** é verificado na borda (`require_role` no router). Regras que dependem do
  **dado** (ex.: só o autor edita o post) ficam no service, que recebe o usuário atual e
  lança `ForbiddenError`:
  ```python
  async def update_post(self, post_id: UUID, data: PostUpdate, actor: User) -> Post:
      post = await get_or_404(self.repo.find_by_id, post_id, "Post não encontrado")
      if post.author_id != actor.id and actor.role != UserRole.ADMIN:
          raise ForbiddenError("Sem permissão para editar este post")
      ...
  ```
- Refresh tokens são persistidos como hash e rotacionados (ver [Refresh tokens](refresh-tokens.md)).
- O envio de e-mail é uma dependência externa: **mockado nos testes** (ver
  [Testes unitários](../testing/backend-unit.md)).

---

**Veja também:** [Exceções de domínio](../backend/exceptions.md) · [OTP e JWT](otp.md)
