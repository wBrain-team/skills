# Comportamento do agente

[← Diretrizes](guidelines.md)

## Antes de qualquer implementação
- Leia os arquivos relevantes antes de editá-los — nunca edite sem ler.
- Consulte o guia temático correspondente sempre que for implementar testes, endpoints ou componentes.
- Use `TodoWrite` para planejar tarefas com múltiplos passos.
- Em caso de dúvida sobre o escopo, pergunte antes de implementar.

## Confirmação obrigatória antes de executar
- Deletar arquivos ou diretórios.
- Force push ou reset hard no git.
- Operações destrutivas em banco de dados (DROP, TRUNCATE fora de testes).
- Qualquer ação que afete ambiente de produção.

## Restrições de execução
- Nunca instale dependências diretamente na máquina local — use Docker.
- Nunca commite arquivos `.env`, secrets ou credenciais.
- Nunca use `--no-verify` para bypassar hooks git.
- Nunca faça amend em commits já publicados no repositório remoto.

---

**Veja também:** [Segurança](security.md) · [Git](git.md)
