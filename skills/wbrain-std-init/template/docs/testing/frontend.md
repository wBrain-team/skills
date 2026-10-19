# Testes unitários — frontend

[← Testes](testing.md)

Testam componentes e hooks de forma isolada, sem chamadas HTTP reais.

- Moque chamadas de API com `vi.mock` (Vitest) ou `msw` (Mock Service Worker).
- Teste comportamento visível ao usuário — não teste detalhes de implementação.
- Nomenclatura: `describe` por componente, `it` por comportamento.
- Telas com `DataList`: use `getAllByText` (não `getByText`) — o mesmo conteúdo aparece na
  tabela desktop e nos cards mobile.
- O setup do Vitest importa `lib/i18n` (locale `pt-BR`), então os componentes renderizam os
  textos traduzidos reais e as asserções usam esses textos — uma chave sem tradução aparece
  como a própria chave e faz o teste falhar.

```typescript
// frontend/src/tests/components/LoginForm.test.tsx

describe("LoginForm", () => {
  it("exibe erro quando email é inválido", async () => {
    render(<LoginForm />);
    await userEvent.type(screen.getByLabelText("Email"), "email-invalido");
    await userEvent.click(screen.getByRole("button", { name: "Entrar" }));

    expect(screen.getByText("Email inválido")).toBeInTheDocument();
  });

  it("chama onSubmit com email e código ao verificar", async () => {
    const onSubmit = vi.fn();
    render(<LoginForm onSubmit={onSubmit} />);

    await userEvent.type(screen.getByLabelText("Email"), "user@test.com");
    await userEvent.type(screen.getByLabelText("Código"), "123456");
    await userEvent.click(screen.getByRole("button", { name: "Entrar" }));

    expect(onSubmit).toHaveBeenCalledWith({ email: "user@test.com", code: "123456" });
  });
});
```

---

**Veja também:** [DataList](../frontend/data-list.md) · [Formulários](../frontend/forms.md)
