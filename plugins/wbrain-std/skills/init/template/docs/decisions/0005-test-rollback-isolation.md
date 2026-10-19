# ADR-0005 — Isolamento de testes por rollback com savepoint

[← Decisões](decisions.md)

- **Status:** Aceito
- **Data:** 2026-10-13

## Contexto

Os testes de API usavam um Postgres dedicado (`db-test`, em `tmpfs`) e truncavam todas
as tabelas antes de cada teste. O custo cresce com o número de tabelas e de testes, e o
modelo não permite execução paralela.

## Decisão

Manter o Postgres dedicado e isolar cada teste numa transação desfeita ao final, com
`join_transaction_mode="create_savepoint"` (os commits da aplicação viram savepoints).
O `TRUNCATE` fica restrito à fixture `committing_db_session`, para testes que precisam
de commits reais visíveis a outras conexões.

Alternativas descartadas: SQLite em memória (não reflete o Postgres) e Testcontainers /
pytest-postgresql (exigiriam Docker dentro de Docker, já que os testes rodam em
containers).

## Consequências

- Isolamento quase gratuito; sem `TRUNCATE` por teste.
- Factories usam `sqlalchemy_session_persistence = "flush"`.
- Código que abre a própria sessão (jobs) precisa da fixture de commits reais.
- Paralelismo futuro via um banco por worker (`CREATE DATABASE ... TEMPLATE`).
- Detalhes em [Banco de teste e conftest](../testing/test-database.md).
