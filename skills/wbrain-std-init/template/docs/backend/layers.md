# Camadas do backend

[← Backend](backend.md)

Cada camada tem responsabilidade única e só se comunica com a camada imediatamente abaixo.

```
Request HTTP
    ↓
Router (api/)        → valida schema Pydantic, chama service, retorna resposta HTTP
    ↓
Service (services/)  → lógica de negócio, orquestra repository, lança exceções de domínio
    ↓
Repository (*)       → acesso ao banco via SQLAlchemy, queries, sem lógica de negócio
    ↓
Model (models/)      → definição das tabelas e relacionamentos
```

**Regras:**
- Routers nunca acessam o banco diretamente — sempre via service.
- Services nunca constroem respostas HTTP — lançam exceções de domínio.
- Lógica de negócio nunca vive no router — pertence ao service.
- Todo acesso a dados passa por um repository (obrigatório) — services nunca usam a sessão
  nem montam queries diretamente.
- Services recebem suas dependências (repositories, `EmailSender` etc.) **por argumento
  nomeado no construtor**, o que permite mocká-las nos testes unitários:
  `UserService(repo=UserRepository(db))`.
- Autorização por **papel** fica na borda (`require_role` no router); regras que dependem
  do **dado** (ex.: só o autor edita o post) ficam no service, que lança `ForbiddenError`
  (ver [RBAC](../auth/rbac.md)).

## Transação e commit

O dono do commit é quem abre a sessão — **nunca** o repository nem o service:

- Em requests HTTP, o `get_db` faz commit ao final (ou rollback em exceção) — a request
  inteira é uma transação atômica (ver [Banco de dados](database.md)).
- Fora de HTTP (jobs, scripts, seed), o próprio script faz o commit (ver [Jobs](jobs.md)).
- Repositories fazem no máximo `flush` (para obter ids e defaults do banco); services não
  chamam `commit()`.

## Checklist de revisão — antes de marcar uma tarefa como concluída

Ao finalizar qualquer implementação de backend, verifique cada item:

- [ ] A lógica de negócio está no `service`, não no `router`?
- [ ] O `router` só valida schema Pydantic, chama o service e retorna resposta?
- [ ] O `service` lança `DomainException` (nunca `HTTPException`)?
- [ ] Todo acesso a dados está no `repository` (nenhum `commit()` em repository/service)?
- [ ] Reaproveitou as peças compartilhadas (`BaseRepository` + `build_order_by`/`build_search_filter`, `get_or_404`/`ensure_unique`, `serialize`/`serialize_list`/`paginate`/`Pagination`, `PageMeta` + `optional`/`strip_required`) em vez de duplicar o padrão?
- [ ] O handler global em `main.py` cobre todas as exceções de domínio usadas?
- [ ] A resposta segue o contrato da API (`{"data": ...}` ou `{"error": ...}`)?
- [ ] Os testes unitários cobrem a lógica do `service` com mocks?
- [ ] Os testes de API cobrem todos os status codes documentados para o endpoint?

---

**Veja também:** [Peças reutilizáveis](shared-pieces.md) · [Exceções de domínio](exceptions.md) · [Contrato da API](api-contract.md)
