# Refresh tokens — persistência e rotação

[← Autenticação](auth.md)

O refresh token é **opaco** (aleatório, não JWT), gravado no banco **só como hash** e
**rotacionado** a cada uso. Isso permite revogação real: logout, troca de dispositivo ou
suspeita de roubo invalidam o token antes de ele expirar.

## Modelo `RefreshToken`

```python
# app/models/refresh_token.py
class RefreshToken(Base):
    __tablename__ = "refresh_tokens"
    __audit_exclude__ = True              # infra: não auditar (ver docs/backend/audit-log.md)

    id: Mapped[uuid] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[uuid] = mapped_column(ForeignKey("users.id"), index=True)
    token_hash: Mapped[str] = mapped_column(unique=True)  # HASH do token, nunca o token em si
    expires_at: Mapped[datetime]
    revoked_at: Mapped[datetime | None] = mapped_column(default=None)
```

## Emissão e hash

```python
# app/core/security.py
def generate_refresh_token() -> str:
    return secrets.token_urlsafe(32)

def hash_refresh_token(token: str) -> str:
    # token de alta entropia: SHA-256 basta (não precisa de HMAC nem de hash lento)
    return hashlib.sha256(token.encode()).hexdigest()
```

## Rotação, reuso e logout

```python
# app/services/auth_service.py (esboço)
class AuthService:
    async def issue_refresh_token(self, user_id: UUID) -> str:
        token = generate_refresh_token()
        await self.refresh_tokens.create(RefreshToken(
            user_id=user_id,
            token_hash=hash_refresh_token(token),
            expires_at=utcnow() + timedelta(days=settings.refresh_token_expire_days),
        ))
        return token

    async def refresh(self, refresh_token: str) -> TokenPair:
        stored = await self.refresh_tokens.find_by_hash(hash_refresh_token(refresh_token))
        if stored is None or stored.expires_at <= utcnow():
            raise UnauthorizedError("Sessão expirada")
        if stored.revoked_at is not None:
            # token já rotacionado sendo reutilizado → provável roubo: derruba todas as sessões
            await self.refresh_tokens.revoke_all_for_user(stored.user_id)
            raise UnauthorizedError("Sessão expirada")
        await self.refresh_tokens.revoke(stored)
        return TokenPair(
            access_token=create_access_token(sub=str(stored.user_id)),
            refresh_token=await self.issue_refresh_token(stored.user_id),
        )

    async def logout(self, refresh_token: str) -> None:
        stored = await self.refresh_tokens.find_by_hash(hash_refresh_token(refresh_token))
        if stored is not None and stored.revoked_at is None:
            await self.refresh_tokens.revoke(stored)  # idempotente: token inválido não é erro

    async def purge_expired_refresh_tokens(self) -> None:
        await self.refresh_tokens.delete_expired_or_revoked(older_than=utcnow())
```

**Regras:**
- Nunca grave, logue ou retorne um refresh token já emitido — só o hash fica no banco.
- Cada `refresh` revoga o token usado e emite um novo par; o cliente **sempre** substitui
  os dois tokens.
- Reuso de um token revogado revoga **todas** as sessões do usuário.
- A limpeza de tokens expirados/revogados roda no job `expire_tokens` (ver
  [Jobs](../backend/jobs.md)).

---

**Veja também:** [Fluxo](flow.md) · [OTP e JWT](otp.md) · [Auth no frontend](frontend.md)
