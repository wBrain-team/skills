# ADR-0002 — JSON da API em snake_case de ponta a ponta

[← Decisões](decisions.md)

- **Status:** Aceito
- **Data:** 2026-10-13

## Contexto

O backend devolvia snake_case (`page_size`, `is_active`), mas os tipos do frontend
esperavam camelCase (`pageSize`, `isActive`) sem nenhuma conversão — o código gerado a
partir dos docs leria campos inexistentes.

## Decisão

Todo JSON que trafega na API — requests, responses e query params — usa snake_case.
Nenhuma ponta converte case: o frontend lê e emite exatamente o formato da API.

## Consequências

- Sem camada de conversão para manter nem bugs de mapeamento entre as pontas.
- Os tipos TypeScript de dados da API usam snake_case, fugindo do camelCase usual do
  TS; o ESLint precisa aceitar snake_case em propriedades.
- Estado interno do frontend (ex.: store de auth) segue camelCase; a tradução acontece
  no ponto de chamada.
- Regras em [Contrato da API](../backend/api-contract.md#formato-dos-campos--snake_case) e
  [Comunicação com a API](../frontend/api-client.md#formato-dos-dados--snake_case).
