# Logging e observabilidade

[← Backend](backend.md)

Logging estruturado configurado uma vez em `app/core/logging.py` e obtido via
`logging.getLogger(__name__)` nos módulos.

```python
import logging

logger = logging.getLogger(__name__)
logger.info("user_created", extra={"request_id": request_id, "user_id": user.id})
```

**Regras:**
- Propague o `request_id` (capturado pelo middleware de auditoria) nos logs para
  correlacionar uma request de ponta a ponta.
- Nível por ambiente: `DEBUG` em dev, `INFO`/`WARNING` em produção (via `settings.app_env`).
- **Nunca** logue segredos, tokens ou senhas; mascare campos sensíveis.
- **Nunca** exponha stack trace na resposta HTTP de produção — o handler global devolve
  só `{"error": {code, message}}` (ver [Contrato da API](api-contract.md)); o traceback vai para o log.

---

**Veja também:** [Audit log](audit-log.md) · [Contrato da API](api-contract.md)
