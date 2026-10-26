# Rastreabilidade snapshot → teste

Todo teste de regra de negócio aponta para o snapshot que ele garante, com um marcador em comentário:

```python
# snapshot: snapshots/pedidos/regras.md
def test_pedido_acima_de_200_tem_frete_gratis(): ...
```

```ts
// snapshot: snapshots/pedidos/lista.md
it("mostra 20 pedidos por página", () => { ... });
```

- O marcador usa o caminho do **arquivo** de snapshot a partir da raiz do repositório, não a linha: o arquivo é estável e a linha muda a cada edição.
- Um marcador no topo do arquivo de teste vale para todos os testes dele. Um teste pode ter mais de um marcador.
- Testes técnicos (infraestrutura, fumaça) ficam sem marcador.
- Snapshot removida ou renomeada → os marcadores acompanham: testes da regra removida saem, os da renomeada são atualizados.

Verificação: `bash ${CLAUDE_PLUGIN_ROOT}/skills/shared/scripts/snapshot-coverage.sh [snapshots...]` lista, por snapshot, os arquivos de teste que a referenciam, os snapshots sem teste e os marcadores que apontam para snapshot inexistente.
