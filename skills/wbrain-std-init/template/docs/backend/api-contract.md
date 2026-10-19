# Contrato da API

[← Backend](backend.md)

Toda resposta da API segue formato consistente. O frontend pode depender dessa estrutura.

## Formato dos campos — snake_case

Todo JSON que trafega na API — **requests e responses**, inclusive query params — usa
**snake_case** (`page_size`, `is_active`, `access_token`). Não há conversão de case em
nenhuma ponta: os schemas Pydantic expõem os nomes dos atributos como estão, e o frontend
lê e emite exatamente esse formato (ver [Comunicação com a API](../frontend/api-client.md)).

## Resposta de sucesso — recurso único

```json
// POST /api/v1/users → 201
// GET /api/v1/users/{id} → 200
{
  "data": {
    "id": "uuid",
    "name": "João Silva",
    "email": "joao@email.com"
  }
}
```

## Resposta de sucesso — listagem paginada

```json
// GET /api/v1/users?page=1&page_size=20 → 200
{
  "data": [
    { "id": "uuid", "name": "João Silva" }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

## Resposta de erro

```json
// 404
{ "error": { "code": "NOT_FOUND", "message": "Usuário não encontrado" } }

// 409
{ "error": { "code": "CONFLICT", "message": "Email já cadastrado" } }

// 422 (validação Pydantic)
{ "error": { "code": "VALIDATION_ERROR", "message": "Dados inválidos" } }

// 401
{ "error": { "code": "UNAUTHORIZED", "message": "Token inválido ou expirado" } }

// 500 (exceção inesperada — detalhes só no log)
{ "error": { "code": "INTERNAL_ERROR", "message": "Erro interno" } }
```

O envelope de erro vale para **qualquer** falha, inclusive as geradas pelo framework
(validação, rota inexistente, método não permitido) — ver
[handlers globais](exceptions.md#handlers-globais). O `code` é estável e serve para o
frontend traduzir a mensagem.

## Convenções de URL

- Prefixo obrigatório: `/api/v1/`
- Recursos em plural e kebab-case: `/api/v1/users`, `/api/v1/product-categories`
- Relações aninhadas com moderação: `/api/v1/users/{id}/posts`
- Ações não-CRUD via verbo na URL: `/api/v1/users/{id}/activate`

---

**Veja também:** [Exceções de domínio](exceptions.md) · [Peças reutilizáveis (paginação)](shared-pieces.md) · [Erros no frontend](../frontend/ui-states.md)
