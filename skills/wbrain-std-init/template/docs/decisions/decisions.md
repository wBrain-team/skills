# Decisões técnicas (ADRs)

[← Índice](../docs.md)

Cada decisão técnica relevante tem um registro curto e imutável (ADR — *Architecture
Decision Record*). Para mudar uma decisão, crie um ADR novo que a substitua e marque o
antigo como `Substituído por ADR-NNNN` — não reescreva o histórico.

| ADR | Decisão | Status |
|---|---|---|
| [0001](0001-english-code.md) | Código em inglês; idioma do conteúdo livre | Aceito |
| [0002](0002-snake-case-api.md) | JSON da API em snake_case de ponta a ponta | Aceito |
| [0003](0003-mandatory-repository.md) | Camada repository obrigatória; commit fora dela | Aceito |
| [0004](0004-refresh-token-rotation.md) | Refresh token persistido e rotacionado | Aceito |
| [0005](0005-test-rollback-isolation.md) | Isolamento de testes por rollback com savepoint | Aceito |

## Modelo

Arquivo `NNNN-titulo-curto.md` (número sequencial, título em inglês e kebab-case):

```markdown
# ADR-NNNN — Título

[← Decisões](decisions.md)

- **Status:** Proposto | Aceito | Substituído por ADR-NNNN
- **Data:** AAAA-MM-DD

## Contexto
O problema e as forças em jogo.

## Decisão
O que foi decidido, em uma ou duas frases afirmativas.

## Consequências
O que fica mais fácil, o que fica mais difícil e o que precisa ser feito.
```
