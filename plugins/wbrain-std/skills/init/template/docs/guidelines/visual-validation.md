# Validação visual

[← Diretrizes](guidelines.md)

Antes de encerrar uma mudança **de interface**, o agente olha a renderização real. Detalhes técnicos, comandos e armadilhas: [Testes visuais e jornadas E2E](../testing/visual.md).

## Princípios

- **Não reprova por aparência.** O produto é **evidência** (imagens) mais **sinais objetivos**. Quem julga é o agente, abrindo as imagens. Regressão por diff de pixel está fora de escopo.
- **Não substitui teste unitário.** Defeito de comportamento ganha um teste que o reproduz.
- **Jornada E2E é o único teste de navegador que reprova** e é cara; regras em [visual.md](../testing/visual.md#jornadas-e2e).

## Quando

No **fim do ciclo**, depois de verde + cobertura + lint, e **só se a mudança toca interface**. É obrigatória quando o ambiente existe (`PW_TEST_CONNECT_WS_ENDPOINT`). Sem ele, o agente diz que **não foi possível**, nunca finge.

## Como

1. Escolha o **mínimo** de capturas (rotas, temas, tamanhos). Em mudança de **layout**, ao menos mobile, tablet, laptop e wide (`sizes=all`).
2. Gere (`make screenshot ...`).
3. **Abra as imagens e olhe**, conferindo a lista "Detalhes que evidenciam descuido" de `direcao-visual.md` (design-system). Em telas largas: o conteúdo usa o espaço ou fica perdido? Nas estreitas: o que quebra? Sidebar, colunas e tabela→cards trocam bem?
4. Leia os **sinais** (erro de JS, `console.error`, requisição falha, overflow horizontal). Eles **não** cobrem layout, contraste nem foco: só as imagens cobrem.
5. Corrija (com teste antes se for comportamento) e **gere de novo**.
6. No fechamento, **cite** o que foi verificado (rotas, fluxos, temas, tamanhos) e o que **não** foi.

## Regras

- `temp/` nunca vai para git, PR, docs ou snaps.
- Nunca instale navegador ou dependência no host.
- Imagens custam contexto: abra só as necessárias.
- Roteiro do agente fica em `temp/flows/` (descartável); **promover** para `tests/visual/flows/` só com aprovação do tutor.
