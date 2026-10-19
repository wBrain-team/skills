# OTP e emissão de JWT

[← Autenticação](auth.md)

## Modelo `OtpCode`

```python
# app/models/otp_code.py
class OtpCode(Base):
    __tablename__ = "otp_codes"
    __audit_exclude__ = True              # infra: não auditar (ver docs/backend/audit-log.md)

    id: Mapped[uuid] = mapped_column(primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(index=True)
    code_hash: Mapped[str]                # HASH do código, nunca o código em si
    expires_at: Mapped[datetime]
    attempts: Mapped[int] = mapped_column(default=0)
    used_at: Mapped[datetime | None] = mapped_column(default=None)
```

## Geração e verificação do código

Sem `passlib`/senha. O código é gerado com `secrets` e comparado por **HMAC** (hash com
chave do servidor) — comparação em tempo constante. Em `app/core/security.py`:

```python
import hmac, hashlib, secrets
from app.core.config import settings

def generate_otp(length: int = settings.otp_length) -> str:
    return "".join(secrets.choice("0123456789") for _ in range(length))

def hash_otp(code: str) -> str:
    return hmac.new(settings.otp_hash_secret.encode(), code.encode(), hashlib.sha256).hexdigest()

def verify_otp(code: str, code_hash: str) -> bool:
    return hmac.compare_digest(hash_otp(code), code_hash)
```


## Service de OTP e emissão de JWT

```python
# app/services/auth_service.py (esboço)
class AuthService:
    def __init__(self, *, otps: OtpCodeRepository, users: UserRepository,
                 refresh_tokens: RefreshTokenRepository, email: EmailSender):
        self.otps = otps
        self.users = users
        self.refresh_tokens = refresh_tokens
        self.email = email

    async def request_otp(self, email: str) -> None:
        code = generate_otp()
        await self.otps.create(OtpCode(
            email=email,
            code_hash=hash_otp(code),
            expires_at=utcnow() + timedelta(minutes=settings.otp_expire_minutes),
        ))
        await self.email.send(to=email, subject="Seu código de acesso",
                              html=render_otp_email(code))
        # resposta SEMPRE genérica — não revela se o e-mail existe

    async def verify_otp(self, email: str, code: str) -> AuthResult:
        otp = await self.otps.get_active_otp(email)         # não usado e não expirado
        if otp is None or otp.attempts >= settings.otp_max_attempts:
            raise UnauthorizedError("Código inválido ou expirado")
        if not verify_otp(code, otp.code_hash):
            await self.otps.increment_attempts(otp)
            raise UnauthorizedError("Código inválido ou expirado")
        await self.otps.mark_used(otp)
        user = await self.users.get_or_create_by_email(email)
        return AuthResult(
            access_token=create_access_token(sub=str(user.id)),
            refresh_token=await self.issue_refresh_token(user.id),  # ver refresh-tokens.md
            user=user,
        )


def build_auth_service(db: AsyncSession) -> AuthService:
    """Monta o service com suas dependências — usado pela dependency do router e por jobs."""
    return AuthService(
        otps=OtpCodeRepository(db),
        users=UserRepository(db),
        refresh_tokens=RefreshTokenRepository(db),
        email=get_email_sender(),
    )
```

`AuthResult` é o que o `otp/verify` devolve no envelope: `{access_token, refresh_token, user}`.
`create_access_token` (python-jose) assina com `settings.jwt_secret`/`settings.jwt_algorithm`;
a expiração vem das settings; o `sub` carrega o id do usuário. O refresh token é opaco e
persistido — ver [Refresh tokens](refresh-tokens.md).

---

**Veja também:** [Fluxo](flow.md) · [Envio de e-mail](email.md) · [Configuração e settings](../backend/config.md)
