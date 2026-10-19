# Configuração e settings

[← Backend](backend.md)

Toda configuração vive em `app/core/config.py`, num único `Settings(BaseSettings)`
(pydantic-settings) que lê do `.env`. Nunca leia `os.environ` espalhado pelo código —
importe `settings`.

```python
# app/core/config.py

from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_env: Literal["development", "staging", "production"]  # obrigatório, sem default
    database_url: str                         # postgresql+asyncpg://user:pass@db:5432/app_dev

    jwt_secret: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 7

    # OTP (autenticação sem senha — ver docs/auth/otp.md)
    otp_hash_secret: str                      # chave HMAC para hashear o código
    otp_length: int = 6
    otp_expire_minutes: int = 10
    otp_max_attempts: int = 5

    # Envio de e-mail (provedor de OTP)
    email_provider: str = "resend"            # resend | sendgrid
    email_api_key: str
    email_from: str                           # remetente verificado, ex.: "no-reply@app.com"

    default_page_size: int = 20
    max_page_size: int = 100

settings = Settings()  # instância única, importada por todo o app
```

**Regras:**
- Variáveis sensíveis (segredos, chaves de API, URLs com credencial) **só** via `.env` —
  nunca hardcode (ver [Segurança](../guidelines/security.md)).
- Mantenha `.env.example` atualizado com **todas** as chaves (sem valores reais):
  `APP_ENV`, `DATABASE_URL`, `TEST_DATABASE_URL`, `JWT_SECRET`, `JWT_ALGORITHM`,
  `ACCESS_TOKEN_EXPIRE_MINUTES`, `REFRESH_TOKEN_EXPIRE_DAYS`,
  `OTP_HASH_SECRET`, `OTP_LENGTH`, `OTP_EXPIRE_MINUTES`, `OTP_MAX_ATTEMPTS`,
  `EMAIL_PROVIDER`, `EMAIL_API_KEY`, `EMAIL_FROM`,
  `DEFAULT_PAGE_SIZE`, `MAX_PAGE_SIZE`.
- `APP_ENV` é **obrigatório** e restrito aos três valores: ausente ou desconhecido, o app
  não sobe. Nunca dê default a ele — um default `development` liberaria operações dev-only
  num ambiente mal configurado.
- Comportamento dev-only (ex.: `make charge`) compara `settings.app_env == "development"`
  (igualdade exata) — ver [Seed](seed.md).
- `TEST_DATABASE_URL` **não** faz parte de `Settings` (o app não depende dela para subir);
  é lida só pela suíte de testes (ver [Banco de teste](../testing/test-database.md#conftestpy-padrão)).

---

**Veja também:** [Segurança](../guidelines/security.md) · [Banco de dados](database.md) · [Seed](seed.md)
