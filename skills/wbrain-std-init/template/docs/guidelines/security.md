# Segurança

[← Diretrizes](guidelines.md)

- Variáveis sensíveis sempre via variáveis de ambiente (`.env`).
- Mantenha `.env.example` atualizado com todas as chaves necessárias (sem valores reais).
- Valide entradas em todos os endpoints públicos.
- Nunca exponha stack traces em respostas de produção.

---

**Veja também:** [Configuração e settings](../backend/config.md) · [Variáveis de ambiente do frontend](../frontend/env-vars.md) · [Checklist de auth](../auth/auth.md#checklist--antes-de-concluir)
