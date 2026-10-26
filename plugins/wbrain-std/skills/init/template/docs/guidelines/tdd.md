# TDD (Test-Driven Development)

[← Diretrizes](guidelines.md)

O desenvolvimento segue estritamente o loop TDD:

1. Escreva um teste que falha.
2. Escreva o código mínimo para fazê-lo passar.
3. Refatore mantendo os testes verdes.
4. Repita até a funcionalidade estar completa.

**Regras inegociáveis:**
- Nunca crie um arquivo de implementação sem antes criar o teste correspondente.
- A ordem é sempre: arquivo de teste → falha confirmada → implementação → verde.
- Se o teste não puder ser executado imediatamente, escreva-o assim mesmo e sinalize ao usuário.
- Ao finalizar qualquer feature, execute `make test-coverage` e confirme que services estão em 80%+ (linhas e branches); se houve mudança no frontend, execute também `make test-coverage-front` e confirme 80%+ (linhas e branches).

Detalhes em [Testes](../testing/testing.md).

---

**Veja também:** [Testes](../testing/testing.md)
