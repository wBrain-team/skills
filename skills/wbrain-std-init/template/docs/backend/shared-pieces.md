# Peças reutilizáveis das camadas

[← Backend](backend.md)

Para evitar duplicação, cada camada tem utilitários compartilhados. Reaproveite-os antes de reescrever o padrão.

## Repositórios — `app/repositories/base.py`

`BaseRepository[ModelT]` concentra as operações comuns de acesso a dados:

- `find_by_id(id)` — busca pela PK (`session.get`).
- `find_by(column, value)` — busca por coluna única, retornando 1 ou `None`.
- `create(entity)` / `save(entity)` — adicionam à sessão, fazem `flush` e `refresh`
  (**sem commit** — ver [Transação e commit](layers.md#transação-e-commit)).
- `_list_paginated(*, filters, order_by, page, page_size)` — encapsula o padrão
  `count + offset + limit`, retornando `(itens, total)`.

Funções de módulo no mesmo arquivo montam pedaços recorrentes de query:

- `build_order_by(*, sort_by, sort_dir, sortable, default, tiebreak=())` — resolve
  o `order_by` a partir de uma allowlist de colunas (`sortable`), caindo no
  `default` quando `sort_by` é desconhecido.
- `build_search_filter(search, columns)` — monta um `ILIKE` case-insensitive em
  `OR` sobre várias colunas, ou `None` quando `search` é vazio. Como o retorno é
  uma cláusula SQLAlchemy, teste com `is not None` antes de adicionar aos filtros:
  ```python
  search_filter = build_search_filter(search, [User.name, User.email])
  if search_filter is not None:
      filters.append(search_filter)
  ```

Cada repositório concreto herda de `BaseRepository`, define `model` e expõe apenas
o que é específico do domínio (ex.: `UserRepository.find_by_email` é um wrapper
sobre `find_by`; o `list_paginated` monta os `filters` e delega para `_list_paginated`).

```python
class UserRepository(BaseRepository[User]):
    model = User

    async def find_by_email(self, email: str) -> User | None:
        return await self.find_by(User.email, email)
```

## Serviços — `app/services/helpers.py`

- `get_or_404(finder, id, message)` — busca exigindo existência ou lança `NotFoundError`.
- `ensure_unique(finder, value, message, *, exclude_id=None)` — garante unicidade na
  criação (`exclude_id=None`) ou na atualização (passe o id do próprio registro para
  ignorar conflitos com ele mesmo); lança `ConflictError`.

## Routers — `app/api/pagination.py`

- `Pagination` — dependency (`pagination_params`) que valida e devolve `(page, page_size)`
  a partir de `settings.default_page_size`/`max_page_size`.
- `serialize(obj, schema_cls)` — envelope de recurso único `{"data": {...}}`.
- `serialize_list(items, schema_cls)` — envelope de lista sem paginação `{"data": [...]}`.
- `paginate(items, schema_cls, total, page, page_size)` — serializa os itens com o schema
  e monta o envelope `{"data": [...], "pagination": {...}}` (ver [Contrato da API](api-contract.md)).

Os três centralizam o `schema_cls.model_validate(...).model_dump()`; os routers nunca
montam o envelope `{"data": ...}` à mão.

## Schemas — `app/schemas/common.py`

- `PageMeta` — único modelo de metadados de paginação, importado por todos os domínios.
- `validate_and_normalize(is_valid, normalize, error_message)` — fábrica de field
  validators que valida e normaliza (ex.: `slug`/`email` num schema de domínio).
- `optional(validator)` — adapta um validator obrigatório para campos opcionais dos
  schemas `*Update` (repassa `None`, senão aplica o validator); evita repetir o
  `if value is None: return None`.
- `strip_required(error_message)` — validator que remove espaços e rejeita strings
  vazias (ex.: `name` num schema de domínio). Combina com `optional` no schema de update.

---

**Veja também:** [Camadas](layers.md) · [Contrato da API](api-contract.md)
