# Rastreabilidade spec → teste

Todo teste de regra de negócio aponta para a spec que ele garante, com um marcador em comentário:

```python
# spec: specs/pedidos/regras.md
def test_pedido_acima_de_200_tem_frete_gratis(): ...
```

```ts
// spec: specs/pedidos/lista.md
it("mostra 20 pedidos por página", () => { ... });
```

- O marcador usa o caminho do **arquivo** de spec a partir da raiz do repositório, não a linha: o arquivo é estável e a linha muda a cada edição.
- Um marcador no topo do arquivo de teste vale para todos os testes dele. Um teste pode ter mais de um marcador.
- Testes técnicos (infraestrutura, fumaça) ficam sem marcador.
- Spec removida ou renomeada → os marcadores acompanham: testes da regra removida saem, os da renomeada são atualizados.

Verificação: `bash ${CLAUDE_PLUGIN_ROOT}/skills/loop/scripts/spec-coverage.sh [specs...]` lista, por spec, os arquivos de teste que a referenciam, as specs sem teste e os marcadores que apontam para spec inexistente.
