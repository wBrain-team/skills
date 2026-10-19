# Autenticação e autorização

[← Índice](../docs.md)

Autenticação **sem senha**, por **OTP (código de uso único) enviado por e-mail**, com
emissão de **JWT** (access + refresh) e RBAC por papel. O envio de e-mail usa um provedor
externo (Resend/SendGrid) atrás de uma abstração trocável. Este é o fluxo inicial
**sempre**; outros fatores podem ser adicionados depois sem quebrar este contrato.

| Arquivo | Conteúdo |
|---|---|
| [flow.md](flow.md) | Fluxo request → verify → refresh, tokens e logout |
| [otp.md](otp.md) | Modelo `OtpCode`, geração/verificação por HMAC, service e emissão de JWT |
| [refresh-tokens.md](refresh-tokens.md) | Refresh token opaco, persistido como hash, rotação, reuso e logout |
| [email.md](email.md) | Abstração `EmailSender` (Resend/SendGrid) |
| [rbac.md](rbac.md) | `get_current_user`, `require_role` e regras de segurança do backend |
| [frontend.md](frontend.md) | Login em 2 passos, `useAuthStore`, interceptor 401, guards de rota |

## Checklist — antes de concluir

- [ ] OTP gerado com `secrets`, gravado **só como hash**; nunca loggado nem retornado.
- [ ] `otp/request` responde genericamente (202), com rate limit; sem enumeração de e-mail.
- [ ] OTP single-use, com expiração e limite de tentativas aplicados.
- [ ] Refresh token gravado só como hash, rotacionado a cada uso e revogado no logout; reuso revoga todas as sessões.
- [ ] Envio de e-mail atrás de `EmailSender` (Resend/SendGrid via settings) e mockado em testes.
- [ ] Rotas protegidas usam `Depends(get_current_user)`; restrição por papel usa `require_role` no router.
- [ ] Regras de posse do dado (ex.: só o autor edita) estão no service, que lança `ForbiddenError`.
- [ ] Services lançam `UnauthorizedError`/`ForbiddenError`, nunca `HTTPException`.
- [ ] Frontend lê auth só do `useAuthStore`; nada de `localStorage.clear()` no interceptor.
- [ ] Toda rota está sob `RequireAuth`/`PublicRoute`/`DefaultRedirect`.
- [ ] Tokens, segredos e códigos OTP nunca aparecem em logs nem em respostas de erro.

---

**Veja também:** [Configuração e settings](../backend/config.md) · [Exceções de domínio](../backend/exceptions.md) · [Segurança](../guidelines/security.md)
