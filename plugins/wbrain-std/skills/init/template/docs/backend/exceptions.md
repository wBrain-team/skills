# Exceções de domínio

[← Backend](backend.md)

Defina exceções semânticas em `app/core/exceptions.py`. Nunca levante `HTTPException` dentro de services — isso é responsabilidade do handler global.

```python
# app/core/exceptions.py

class DomainException(Exception):
    status_code: int = 500
    code: str = "INTERNAL_ERROR"
    message: str = "Erro interno"

    def __init__(self, message: str | None = None):
        self.message = message or self.__class__.message
        super().__init__(self.message)

class NotFoundError(DomainException):
    status_code = 404
    code = "NOT_FOUND"
    message = "Recurso não encontrado"

class ConflictError(DomainException):
    status_code = 409
    code = "CONFLICT"
    message = "Conflito com estado atual do recurso"

class UnauthorizedError(DomainException):
    status_code = 401
    code = "UNAUTHORIZED"
    message = "Não autorizado"

class ForbiddenError(DomainException):
    status_code = 403
    code = "FORBIDDEN"
    message = "Sem permissão para esta operação"

class ValidationError(DomainException):
    status_code = 422
    code = "VALIDATION_ERROR"
    message = "Dados inválidos"
```

## Handlers globais

Os handlers em `app/main.py` garantem que **toda** resposta de erro siga o
[contrato](api-contract.md#resposta-de-erro) `{"error": {code, message}}` — não só as
exceções de domínio, mas também validação do Pydantic, erros HTTP do framework (rota
inexistente, método não permitido) e exceções inesperadas:

```python
# app/main.py

from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

HTTP_ERROR_CODES = {401: "UNAUTHORIZED", 403: "FORBIDDEN", 404: "NOT_FOUND", 405: "METHOD_NOT_ALLOWED"}


def error_response(status_code: int, code: str, message: str) -> JSONResponse:
    return JSONResponse(status_code=status_code, content={"error": {"code": code, "message": message}})


@app.exception_handler(DomainException)
async def domain_exception_handler(request: Request, exc: DomainException):
    return error_response(exc.status_code, exc.code, exc.message)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return error_response(422, "VALIDATION_ERROR", "Dados inválidos")


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    code = HTTP_ERROR_CODES.get(exc.status_code, "HTTP_ERROR")
    return error_response(exc.status_code, code, str(exc.detail))


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.exception("unhandled_error")  # traceback só no log, nunca na resposta
    return error_response(500, "INTERNAL_ERROR", "Erro interno")
```

**Regras:**
- Registre `StarletteHTTPException` (não o `HTTPException` do FastAPI) — é ele que cobre
  os 404/405 gerados pelo roteamento.
- O handler genérico **nunca** inclui `str(exc)` nem traceback na resposta.
- Ao criar um `code` novo, adicione a tradução correspondente no frontend
  (`errors.<code>`, ver [i18n](../frontend/i18n.md)).

---

**Veja também:** [Contrato da API](api-contract.md) · [Camadas](layers.md)
