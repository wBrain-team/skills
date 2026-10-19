# Envio de e-mail — abstração de provedor

[← Autenticação](auth.md)

O envio fica atrás de uma interface `EmailSender`, para trocar Resend ↔ SendGrid sem
tocar no service de auth. A implementação concreta é escolhida por `settings.email_provider`.

```python
# app/core/email.py
from typing import Protocol

class EmailSender(Protocol):
    async def send(self, *, to: str, subject: str, html: str) -> None: ...

class ResendEmailSender:          # provedor padrão
    def __init__(self, api_key: str, sender: str): ...
    async def send(self, *, to, subject, html) -> None:
        # POST https://api.resend.com/emails (httpx)
        ...

class SendgridEmailSender:        # alternativa
    ...

def get_email_sender() -> EmailSender:
    if settings.email_provider == "sendgrid":
        return SendgridEmailSender(settings.email_api_key, settings.email_from)
    return ResendEmailSender(settings.email_api_key, settings.email_from)
```

---

**Veja também:** [OTP e JWT](otp.md)
