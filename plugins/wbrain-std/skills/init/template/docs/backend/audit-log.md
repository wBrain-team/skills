# Audit log (auditoria transversal)

[← Backend](backend.md)

Toda criação/edição/exclusão de entidade de domínio é registrada automaticamente
na tabela `audit_logs`, sem instrumentação manual nos endpoints. A captura ocorre
nos eventos de sessão do SQLAlchemy (`before_flush` / `after_flush`), na MESMA
transação da mutação — um rollback desfaz também o log.

**Componentes** (`app/core/audit/`):
- `middleware.py` — captura `request_id`, path, método, IP e user agent da request.
- `context.py` — grava a origem em `session.info`: `get_db` copia os dados do middleware,
  `get_current_user` acrescenta o ator; para mutações fora de HTTP (jobs/scripts), o helper
  `audit_system_context(session, actor=...)` preenche o mesmo `session.info`.
- `listener.py` — calcula o diff campo-a-campo, mascara campos sensíveis e grava
  o `AuditLog`. O contexto é lido **sempre** de `session.info` — nunca de `contextvars`,
  que não atravessam com segurança o greenlet do `AsyncSession`.

Cada entrada guarda, além do **diff** (só os campos alterados), um **snapshot** do
estado completo do registro no momento da ação — assim a consulta mostra o registro
inteiro com destaque para o que mudou, dando contexto de "de quem/de que" é o log.
Diff e snapshot são colunas **`JSONB`** (Postgres), consultáveis com operadores nativos
(`->>`, `@>`) e indexáveis por GIN quando preciso filtrar por conteúdo.

**Configuração declarativa por modelo** (atributos de classe):
- `__audit_exclude__ = True` — não audita (infra: `AuditLog`, `OtpCode`, `RefreshToken`).
- `__audit_sensitive__ = {"field", ...}` — registra a mudança mas mascara o valor
  como `"***"` (antes e depois).
- `__audit_ignore_fields__` — campos ignorados no diff (default: `created_at`,
  `updated_at`).
- `__audit_label_fields__` — campos que compõem o **rótulo legível** do registro
  afetado (ex.: `User = ("name", "email")`), fotografado no momento da ação e
  exibido na consulta para identificar de quem é o log (não só a PK). Sem
  declaração, usa heurística (`name`/`title`/`email`...).

Entidades novas são auditadas **por padrão** (opt-out). Consulta restrita a
administradores em `GET /api/v1/audit-logs` (filtros, busca textual, paginação).

> **Limitação importante:** os eventos de flush NÃO disparam para DML em massa
> (`session.execute(insert()/update()/delete())`, `bulk_save_objects`,
> `bulk_insert_mappings`, `bulk_update_mappings`) — essas operações **não são
> auditadas**. Para entidades de domínio, use sempre operações ORM por objeto.

---

**Veja também:** [Banco de dados](database.md) · [Jobs](jobs.md)
