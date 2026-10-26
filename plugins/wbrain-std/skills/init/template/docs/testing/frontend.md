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

## Cobertura

Mínimo de **80% de linhas e de branches** em `packages/ui` e em cada app (`apps/*`), medido com `make test-coverage-front` (`vitest run --coverage`). O limite fica no `vitest.config.ts` de cada pacote, então o comando falha abaixo dele:

```typescript
// vitest.config.ts (em cada pacote)
test: {
  coverage: {
    provider: "v8",
    include: ["src/**/*.{ts,tsx}"],
    exclude: ["src/**/*.test.{ts,tsx}", "src/tests/**", "src/main.tsx", "src/**/*.d.ts"],
    reporter: ["text", "html"],
    thresholds: { lines: 80, branches: 80 },
  },
}
```

- Workspace novo herda a mesma configuração e o mesmo limite.
- Suba o número com testes de comportamento (estados, teclado, `aria-*`, erros), não com testes sem asserção.
- Exclusão de arquivo da medição exige justificativa no próprio `vitest.config.ts` (comentário).

---

**Veja também:** [DataList](../frontend/data-list.md) · [Formulários](../frontend/forms.md)
