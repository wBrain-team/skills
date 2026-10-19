# Fixtures e factories

[← Testes](testing.md)

## Seed de dados — factory_boy

Use `factory_boy` com `SQLAlchemyModelFactory`. Não use factories manuais — `factory_boy` resolve sequências automáticas, relações (`SubFactory`) e atributos calculados (`LazyAttribute`).

Nunca dependa de dados deixados por outro teste — cada teste cria explicitamente o que precisa.

```python
# src-backend/app/tests/factories.py

import factory
from factory.alchemy import SQLAlchemyModelFactory
from app.models import User, Post

class UserFactory(SQLAlchemyModelFactory):
    class Meta:
        model = User
        sqlalchemy_session_persistence = "flush"  # grava na transação do teste, sem commit

    name = factory.Faker("name", locale="pt_BR")
    email = factory.Sequence(lambda n: f"user{n}@test.com")  # garante unicidade
    is_active = True
    # autenticação é por OTP/e-mail (sem senha) — User não tem password_hash

class PostFactory(SQLAlchemyModelFactory):
    class Meta:
        model = Post
        sqlalchemy_session_persistence = "flush"

    title = factory.Faker("sentence", locale="pt_BR")
    author = factory.SubFactory(UserFactory)  # cria o User automaticamente
```

Use `"flush"` (não `"commit"`): o registro fica visível para a sessão do teste — e para o
app, que usa a mesma sessão via `client` — e é descartado no rollback final (ver
[isolamento](test-database.md#isolamento-rollback-por-teste)).

## Fixtures e utilitários compartilhados (deste projeto)

Para não repetir setup entre os arquivos de `tests/api/`, dois utilitários são centralizados:

- **`bind_factories`** (fixture em `app/tests/conftest.py`) — liga **todas** as factories
  (`UserFactory`, `PostFactory`, `AuditLogFactory`) à `db_session` do teste.
  Basta declarar o parâmetro `bind_factories` no teste; não redefina a fixture localmente
  nem atribua `_meta.sqlalchemy_session` à mão.
- **`auth_headers(user_id)` / `admin_headers(user_id)`** (em `app/tests/helpers.py`) — geram
  o header `Authorization` com um access token JWT real. São o mesmo helper (alias), nomeados
  conforme a intenção do teste. Login é por OTP/e-mail (ver [fluxo](../auth/flow.md)); em
  teste não passamos pelo envio de e-mail — o token é emitido direto para o usuário criado.

```python
# src-backend/app/tests/helpers.py
from app.core.security import create_access_token

def auth_headers(user_id) -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(sub=str(user_id))}"}

admin_headers = auth_headers  # alias: deixa explícita a intenção do teste
```

```python
from app.tests.helpers import admin_headers


async def test_list_posts(client, bind_factories):
    admin = UserFactory(role=UserRole.ADMIN)
    response = await client.get("/api/v1/posts", headers=admin_headers(admin.id))
    assert response.status_code == 200
```

---

**Veja também:** [Banco de teste e conftest](test-database.md) · [Seed de dev](../backend/seed.md)
