# ADR-0003 — Camada repository obrigatória; commit fora dela

[← Decisões](decisions.md)

- **Status:** Aceito
- **Data:** 2026-10-13

## Contexto

Os docs diziam que o repository podia ser omitido em projetos simples, mas o checklist,
a estrutura de pastas e os exemplos o tratavam como obrigatório. Também não estava
definido quem faz o commit: o `get_db`, o repository ou o service.

## Decisão

- Todo acesso a dados passa por um repository (`BaseRepository` + um por entidade).
- Services recebem suas dependências por argumento nomeado no construtor.
- Quem abre a sessão faz o commit: o `get_db` em requests HTTP, o próprio script em
  jobs/seed. Repositories fazem no máximo `flush`; services nunca fazem commit.

## Consequências

- Cada request é uma transação atômica: um erro no meio desfaz tudo.
- Services são testáveis com repositories mockados.
- Um pouco mais de código em domínios triviais, em troca de um padrão único.
- Regras em [Camadas do backend](../backend/layers.md#transação-e-commit).
