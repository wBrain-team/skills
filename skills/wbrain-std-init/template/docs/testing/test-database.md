# Banco de teste e conftest

[← Testes](testing.md)

## Container de banco de teste

O `docker-compose.yml` deve conter um serviço `db-test` separado do banco de desenvolvimento:

```yaml
# docker-compose.yml (trecho)
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_DB: app_dev
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"

  db-test:
    image: postgres:17
    environment:
      POSTGRES_DB: app_test
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5433:5432"
    tmpfs:
      - /var/lib/postgresql/data   # banco em memória RAM: mais rápido e descartável
```

A variável `TEST_DATABASE_URL` no `.env.example` deve apontar para `db-test:5432`.

## Isolamento: rollback por teste

Cada teste roda dentro de uma transação que é **desfeita ao final** — nada do que o teste
grava sobrevive para o próximo, sem precisar truncar tabelas.

```
sessão:  alembic upgrade head (1×) → engine compartilhado
teste:   abre conexão → BEGIN → teste (commits viram SAVEPOINTs) → ROLLBACK
```

A sessão do teste usa `join_transaction_mode="create_savepoint"` (SQLAlchemy 2.x): os
`commit()`/`rollback()` do código da aplicação passam a operar sobre **savepoints** dentro
da transação externa. A aplicação se comporta como em produção, mas o rollback final
descarta tudo.

O engine usa `NullPool`: cada teste abre a própria conexão no event loop em que roda,
evitando conexões de pool presas a outro loop do pytest-asyncio.

## conftest.py padrão

```python
# src-backend/app/tests/conftest.py

import pytest
from alembic import command
from alembic.config import Config
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.pool import NullPool

from app.core.db import Base, get_db
from app.main import app
from app.tests.factories import AuditLogFactory, PostFactory, UserFactory

FACTORIES = (UserFactory, PostFactory, AuditLogFactory)


class TestSettings(BaseSettings):
    """Configuração só da suíte — fora do Settings do app, que não depende dela para subir."""
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    test_database_url: str


test_settings = TestSettings()


@pytest.fixture(scope="session")
def engine():
    """Aplica as migrations uma vez por sessão e devolve o engine compartilhado."""
    alembic_cfg = Config("alembic.ini")
    alembic_cfg.set_main_option(
        "sqlalchemy.url", test_settings.test_database_url.replace("+asyncpg", "+psycopg")
    )
    command.upgrade(alembic_cfg, "head")
    return create_async_engine(test_settings.test_database_url, poolclass=NullPool)


@pytest.fixture
async def db_session(engine):
    """Sessão dentro de uma transação desfeita ao final do teste."""
    async with engine.connect() as conn:
        outer = await conn.begin()
        session = AsyncSession(
            bind=conn,
            expire_on_commit=False,
            join_transaction_mode="create_savepoint",
        )
        yield session
        await session.close()
        await outer.rollback()


@pytest.fixture
def bind_factories(db_session):
    """Liga todas as factories à sessão do teste."""
    for factory in FACTORIES:
        factory._meta.sqlalchemy_session = db_session


@pytest.fixture
async def client(db_session):
    """Cliente HTTP que usa a sessão do teste com o mesmo contrato do get_db."""

    async def _get_test_db():
        # espelha o get_db: commit no sucesso, rollback em exceção — aqui sobre savepoints.
        # Se o get_db ganhar responsabilidades (ex.: session.info de auditoria), replique-as.
        try:
            yield db_session
            await db_session.commit()
        except Exception:
            await db_session.rollback()
            raise

    app.dependency_overrides[get_db] = _get_test_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest.fixture
async def committing_db_session(engine):
    """
    Exceção ao rollback: commits reais, visíveis a outras conexões. Use só quando o código
    sob teste abre a própria sessão (ex.: jobs) ou depende de concorrência entre conexões.
    Trunca as tabelas ao final para não vazar dados.
    """
    async with AsyncSession(engine, expire_on_commit=False) as session:
        yield session
    async with engine.begin() as conn:
        tables = ", ".join(t.name for t in Base.metadata.sorted_tables)
        if tables:
            await conn.execute(text(f"TRUNCATE TABLE {tables} RESTART IDENTITY CASCADE"))
```

**Regras:**
- O padrão é `db_session` (rollback). `committing_db_session` é exceção e deve ser justificada
  no teste — ela é mais lenta e não pode rodar em paralelo com outros testes no mesmo banco.
- Nunca crie engine ou sessão própria dentro de um teste; use as fixtures.
- Nunca dependa de dados deixados por outro teste — cada teste cria o que precisa via factories.

## Execução paralela (quando a suíte crescer)

O rollback isola testes **no mesmo banco**, mas `pytest-xdist` com vários workers ainda
compartilharia o `db-test`. Quando o paralelismo fizer falta, use **um banco por worker**
criado a partir de um template:

1. Aplique as migrations uma vez num banco template (`app_test`).
2. Cada worker cria o seu com `CREATE DATABASE app_test_<worker_id> TEMPLATE app_test`
   (cópia em milissegundos) e aponta o engine para ele — o `worker_id` vem da fixture
   homônima do xdist.
3. Testes com `committing_db_session` também ficam isolados, pois cada worker tem seu banco.

---

**Veja também:** [Testes de API](backend-api.md) · [Fixtures e factories](fixtures-factories.md)
