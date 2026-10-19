# Migrations (Alembic)

[← Backend](backend.md)

O schema evolui **exclusivamente** por migrations Alembic — nunca altere tabelas à mão.

**Fluxo:**
1. Altere/inclua o modelo SQLAlchemy em `app/models/`.
2. Gere a migration: `make migration name=<short_description>` (autogenerate).
3. **Revise o arquivo gerado** em `alembic/versions/` — o autogenerate erra com
   `server_default`, tipos `ENUM`, índices e renomeações. Ajuste `upgrade()`/`downgrade()`.
4. Aplique: `make migrate`.
5. Valide o ciclo completo: `make test-migration` (upgrade → downgrade → re-upgrade no
   banco de teste).

**Regras:**
- Uma migration por mudança lógica; mensagem descritiva.
- `downgrade()` sempre implementado e reversível.
- **Nunca** edite uma migration já aplicada em ambiente remoto — crie uma nova.
- Migrations de dados em massa (`INSERT`/`UPDATE` via `op.execute`) **não passam pelo
  ORM** e, portanto, **não são auditadas** (ver limitação em [Audit log](audit-log.md)).

---

**Veja também:** [Banco de dados](database.md) · [Makefile](../stack/makefile.md)
