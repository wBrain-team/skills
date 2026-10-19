# Banco de dados e sessão

[← Backend](backend.md)

`app/core/db.py` centraliza o engine async, a fábrica de sessão, a `Base` declarativa
e a dependency `get_db`. Os routers/services recebem a sessão por injeção — nunca criam
engine/sessão por conta própria.

```python
# app/core/db.py

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings

class Base(DeclarativeBase):
    pass

engine = create_async_engine(settings.database_url, pool_pre_ping=True)
async_session = async_sessionmaker(engine, expire_on_commit=False)


async def get_db() -> AsyncSession:
    """Sessão por request: commit no sucesso, rollback em exceção."""
    async with async_session() as session:
        # popula session.info para o listener de auditoria (origem da request)
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

Uso no router via `Depends(get_db)`:

```python
@router.get("/api/v1/users")
async def list_users(db: AsyncSession = Depends(get_db)):
    return await UserService(repo=UserRepository(db)).list_paginated(...)
```

> O `session.info` é o ponto onde o contexto de auditoria é preenchido (ver [Audit log](audit-log.md)).
> Por isso a sessão de uma request é sempre obtida via `get_db`. Fora de HTTP, use
> `audit_system_context(session, actor=...)` (ver [Jobs](jobs.md)).

---

**Veja também:** [Migrations](migrations.md) · [Audit log](audit-log.md)
