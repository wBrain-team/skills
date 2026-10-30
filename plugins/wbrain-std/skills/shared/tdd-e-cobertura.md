# TDD e cobertura: os `docs/` são a lei

Regra comum às skills que gravam código (`design-system`, `tuning`, `loop`). **Como** desenvolver está em `docs/`, e a skill o segue com rigor: a skill define o fluxo da conversa, mas nunca afrouxa o que `docs/` exige. Em conflito entre o texto da skill e `docs/guidelines/tdd.md` ou `docs/testing/`, vale o mais rigoroso. As restrições próprias de cada skill (ex.: a `tuning` não altera `snaps/`) continuam valendo.

## 1. Antes da primeira linha de código
Leia `docs/guidelines/tdd.md`, `docs/guidelines/agent-behavior.md`, `docs/testing/testing.md` e o doc da camada (`backend-*.md`, `frontend.md`, `fixtures-factories.md`). Anote para si: o comando de teste pontual, o comando de cobertura e os **mínimos de cobertura** que esses docs fixam. Nada disso é inventado pela skill.

## 2. Ciclo por unidade (arquivo, componente, página, endpoint, service)
1. **Teste primeiro:** crie ou estenda o arquivo de teste antes de qualquer arquivo de implementação. Nunca crie implementação sem o teste correspondente.
2. **Vermelho confirmado:** rode o teste pontual e confira que ele **falha, e pelo motivo certo** (comportamento ausente, não erro de sintaxe ou import). Sem vermelho confirmado, não implemente. Se o teste não puder rodar, escreva-o mesmo assim e sinalize ao usuário (`tdd.md`).
3. **Implementação mínima** até o verde.
4. **Refactor** com os testes verdes.

Código gerado ou copiado (ex.: `make shadcn component=<nome>`) é implementação: o teste do comportamento esperado vem antes e falha primeiro (por exemplo, pelo import do componente que ainda não existe); só depois se gera e customiza o componente.

Peça sem comportamento testável (valor de token CSS, texto estático) não precisa de teste de lógica, mas a página ou o componente que a usa tem teste de renderização.

## 3. Cobertura ao finalizar
Ao fim do trabalho, rode os comandos de cobertura que `docs/` define (`make test-coverage` no backend e `make test-coverage-front` no frontend) e compare com os mínimos de `docs/testing/testing.md` e `tdd.md`.

- **Abaixo do mínimo:** escreva os testes que faltam (primeiro o que cobre regra de negócio e comportamento, não linhas soltas), rode de novo. Conta nos limites de rodadas da skill.
- **Docs sem comando ou mínimo para a camada** (ex.: uma camada que o projeto acrescentou depois): não invente número. Reporte os valores medidos, se der para medir, e proponha ao tutor o texto para `docs/testing/` e `tdd.md`; a decisão é dele.
- Cobertura alta não substitui teste útil: não escreva teste sem asserção só para subir o número.

## 4. Evidência no relatório
O relatório final traz: por unidade, se houve **vermelho confirmado** antes da implementação (e as exceções, com o motivo); os **números de cobertura** medidos contra o mínimo; e o que ficou abaixo, com a razão. Falta de evidência é pendência, não detalhe.
