# Testes de API — backend

[← Testes](testing.md)

Testam os endpoints FastAPI de ponta a ponta contra um banco PostgreSQL real dedicado exclusivamente para testes, rodando em container Docker separado.

**Princípios:**
- Cada teste é isolado, independente e repetível: roda numa transação desfeita ao final
  (ver [Banco de teste e conftest](test-database.md)).
- Cada teste cria explicitamente os dados de que precisa, via factories.
- Nunca use SQLite em memória para testes de API — reflita o ambiente real.
- Use `httpx.AsyncClient` com `ASGITransport` sobre o app FastAPI (sem servidor real) — fixture `client`.
- Valide: status HTTP, corpo da resposta e efeitos colaterais no banco.
- Autenticação: gere tokens reais com `auth_headers`/`admin_headers`, nunca mocke o middleware de auth.

## Exemplos de testes de API

```python
# src-backend/app/tests/api/test_users_router.py

from app.tests.helpers import auth_headers


async def test_post_users_returns_201_with_valid_payload(client):
    response = await client.post("/api/v1/users", json={
        "name": "João",
        "email": "joao@email.com"
    })

    assert response.status_code == 201
    assert response.json()["data"]["email"] == "joao@email.com"
    assert "id" in response.json()["data"]


async def test_post_users_returns_409_when_email_already_exists(client, bind_factories):
    UserFactory(email="existente@email.com")

    response = await client.post("/api/v1/users", json={
        "name": "Outro",
        "email": "existente@email.com"
    })

    assert response.status_code == 409
    assert response.json()["error"]["code"] == "CONFLICT"


async def test_get_users_returns_only_active_users(client, bind_factories):
    requester = UserFactory()
    UserFactory(email="ativo@email.com", is_active=True)
    UserFactory(email="inativo@email.com", is_active=False)

    response = await client.get("/api/v1/users", headers=auth_headers(requester.id))

    assert response.status_code == 200
    emails = [u["email"] for u in response.json()["data"]]
    assert "ativo@email.com" in emails
    assert "inativo@email.com" not in emails
```

---

**Veja também:** [Banco de teste e conftest](test-database.md) · [Fixtures e factories](fixtures-factories.md)
