# Seed de dados de desenvolvimento

[← Backend](backend.md)

`make charge` popula o banco de **dev** com dados fake para acelerar o desenvolvimento.

- **Manual e aditivo** — nunca roda automaticamente; pode ser executado várias vezes.
- **Dev-only** — bloqueado quando `APP_ENV != "development"` (igualdade exata).
- **Reutiliza as factories** (`factory_boy`) definidas em `app/tests/factories.py` — a
  mesma fonte da massa de testes, evitando duplicação (ver [Fixtures e factories](../testing/fixtures-factories.md)).
  As factories só fazem `flush`; o script de seed faz o `commit` ao final.

> Para seed determinístico de produção (ex.: papéis/admin inicial), use uma migration de
> dados versionada, **não** o `make charge`.

---

**Veja também:** [Fixtures e factories](../testing/fixtures-factories.md) · [Migrations](migrations.md)
