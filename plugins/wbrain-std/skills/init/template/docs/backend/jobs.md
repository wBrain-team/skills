# Tarefas agendadas (container `cron`)

[← Backend](backend.md)

Jobs recorrentes (limpeza, sincronizações, relatórios) rodam no container `cron` da
stack, invocando scripts em `app/jobs/`. Um job é uma fina casca de orquestração que
**reutiliza os mesmos services** do app: abre a sessão, monta o service, chama-o e faz o
commit — nunca executa queries nem reimplementa regra de negócio.

```python
# app/jobs/expire_tokens.py

import asyncio
from app.core.db import async_session
from app.core.audit import audit_system_context
from app.services.auth_service import build_auth_service

async def main():
    async with async_session() as db:
        # mutações fora de HTTP precisam de contexto explícito p/ auditar corretamente
        with audit_system_context(db, actor="cron:expire_tokens"):
            await build_auth_service(db).purge_expired_refresh_tokens()
            await db.commit()  # fora de HTTP, quem abre a sessão faz o commit

if __name__ == "__main__":
    asyncio.run(main())
```

**Regras:**
- Mutações fora de uma request HTTP **devem** usar `audit_system_context(session, actor=...)`
  (provido pelo `core/audit`) — ele grava a origem em `session.info`; sem ele o listener
  não tem origem e o log fica órfão.
- Jobs são idempotentes sempre que possível (podem reexecutar sem efeito colateral duplo).
- Erros são logados com contexto; o job sai com status != 0 para o `cron` registrar falha.

---

**Veja também:** [Audit log](audit-log.md) · [Logging](logging.md)
