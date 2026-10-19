# ADR-0004 — Refresh token persistido e rotacionado

[← Decisões](decisions.md)

- **Status:** Aceito
- **Data:** 2026-10-13

## Contexto

O logout falava em "invalidar o refresh, se houver denylist", enquanto um job de exemplo
expirava refresh tokens no banco — o modelo não estava definido. Um refresh token
stateless não pode ser revogado antes de expirar.

## Decisão

O refresh token é opaco, gravado no banco só como hash e rotacionado a cada uso: cada
refresh revoga o token usado e emite um novo par. Reuso de um token já revogado revoga
todas as sessões do usuário. O logout revoga o token no servidor.

## Consequências

- Revogação real: logout, troca de dispositivo e suspeita de roubo têm efeito imediato.
- Uma escrita no banco a cada refresh, e uma tabela `refresh_tokens` que precisa de
  limpeza periódica (job `expire_tokens`).
- O frontend sempre substitui os dois tokens após o refresh (`setTokens`).
- Detalhes em [Refresh tokens](../auth/refresh-tokens.md).
