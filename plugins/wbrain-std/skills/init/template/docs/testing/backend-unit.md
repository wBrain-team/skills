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

## Cobertura

Mínimo de **80% de linhas e de branches** em `app/services/`, medido com `make test-coverage` (`pytest --cov`). O limite fica na configuração do coverage (`pyproject.toml`), então o comando falha abaixo dele:

```toml
[tool.coverage.run]
source = ["app/services"]
branch = true

[tool.coverage.report]
fail_under = 80
show_missing = true
```

- Os testes de API também contam para a medição, mas a regra de negócio precisa estar coberta por testes unitários de service.
- Suba o número com testes de comportamento (regras, erros, permissões, bordas), não com testes sem asserção.
- Exclusão de arquivo da medição exige justificativa em comentário na configuração.

---

**Veja também:** [Testes de API](backend-api.md)
