# Testes unitários — backend

[← Testes](testing.md)

Testam a lógica de negócio em `services/` de forma isolada, sem banco de dados real e sem HTTP.

- Dependências externas (banco, APIs externas, e-mail) devem ser mockadas.
- Um teste por comportamento — não teste implementação, teste resultado.
- Nomenclatura: `test_<acao>_<condicao>_<resultado_esperado>`

```python
# backend/app/tests/unit/test_user_service.py

async def test_create_user_with_existing_email_raises_conflict():
    repo_mock = AsyncMock()
    repo_mock.find_by_email.return_value = existing_user_fixture()

    service = UserService(repo=repo_mock)

    with pytest.raises(ConflictError):
        await service.create(name="Usado", email="usado@email.com")
```

---

**Veja também:** [Testes de API](backend-api.md)
