# Lint de specs

Regras de escrita das specs em `specs/`. Uma spec saudável descreve **o que a aplicação faz agora**, em arquivos pequenos e focados, com regras verificáveis e sem contradições. O agente usa este guia para apontar problemas; quem corrige a spec é sempre o tutor humano.

## 1. Sem passado
A spec não conta a história da mudança. O histórico fica no git.

- ❌ "Antes o desconto era de 5%, agora passa a ser de 10%."
- ✅ "O desconto é de 10%."

## 2. Sem futuro
A spec não registra intenções. O que ainda não vale não entra na spec.

- ❌ "Por enquanto o relatório sai em CSV; depois vamos trocar para PDF."
- ✅ "O relatório é exportado em CSV."

## 3. Presente
Descreva o comportamento no presente, como um fato.

- ❌ "O sistema deverá abrir um menu quando o usuário clicar no botão."
- ✅ "A aplicação abre o menu de ações ao clicar no botão **Opções**."

## 4. Arquivos enxutos, contexto restrito
Um assunto por arquivo. Exemplo: cada componente de frontend tem o seu próprio arquivo de spec, e cada fluxo de negócio também.

Sinais de alerta: um arquivo descreve vários componentes ou fluxos, mistura assuntos sem relação, ou é longo a ponto de ser preciso procurar dentro dele.

- ❌ `specs/frontend.md` descrevendo o cabeçalho, a lista de pedidos e o formulário de cadastro.
- ✅ `specs/frontend/header.md`, `specs/frontend/order-list.md`, `specs/frontend/signup-form.md`.

## 5. Herança (`extends`)
Uma spec pode estender outra, como uma classe filha estende a classe pai. A declaração fica na **primeira linha**, como link Markdown:

```markdown
Extends: [Lista base](../base/data-list.md)
```

- A filha descreve **só o que acrescenta ou sobrescreve**. Não repete o que herda.
- Cada sobrescrita é explícita: "Sobrescreve: a lista mostra 50 itens por página."
- Só um pai por spec e **só um nível**: o pai não estende outra spec. Para reaproveitar mais coisas, use links (regra 7).
- O destino do `extends` existe.

## 6. Comportamento testável
Cada regra é observável e verificável por um teste. Use critérios de aceite (ex.: Dado/Quando/Então) e números no lugar de adjetivos vagos.

- ❌ "A busca deve ser rápida e mostrar bastantes resultados."
- ✅ "A busca responde em até 500 ms e mostra 20 resultados por página."
- ✅ "Dado um pedido pago, quando o cliente o cancela, então o reembolso é criado com status `pending`."

## 7. Termos consistentes e fonte única
- Um termo = um conceito em todas as specs. Não alterne entre sinônimos ("cliente", "usuário", "comprador") para a mesma coisa, nem use o mesmo termo para coisas diferentes.
- Cada regra vive em **um só lugar**. Outras specs fazem referência com link, sem copiar.

- ❌ A regra de cálculo de frete copiada em `checkout.md` e em `order-summary.md`.
- ✅ A regra em `shipping.md`; as outras specs dizem "O frete segue [Frete](shipping.md)."

## 8. O quê, não como
A spec descreve comportamento e regra de negócio, não implementação: nada de classes, tabelas, bibliotecas ou endpoints internos.

- ❌ "Criar a tabela `orders` com a coluna `status` e usar Celery para enviar o e-mail."
- ✅ "Ao confirmar o pedido, o cliente recebe um e-mail de confirmação em até 5 minutos."

Exceção: specs explicitamente técnicas (ex.: um refactor) podem tratar de implementação, desde que se declarem assim no início ("Spec técnica: ...").

## 9. Completude e estrutura
- Casos de borda, erro e permissão estão explícitos: lista vazia, limites, dados inválidos, usuário sem permissão, falha de serviço externo.
- Sem `TODO`, `TBD`, "a definir", "etc." ou reticências no lugar de regra.
- Toda spec é alcançável a partir de `specs/specs.md`, direta ou indiretamente (sem specs órfãs).
- Todos os links internos funcionam.

## Escopo
O lint vale **só para o diff**: linhas adicionadas ou alteradas e arquivos novos. Problemas antigos em trechos não alterados não são reportados. Regras de arquivo inteiro (4 e 9) entram só quando a mudança causa o problema: arquivo novo órfão, ou arquivo que passou a tratar de mais de um assunto por causa do trecho adicionado.

## Formato do retorno do lint
Um achado por linha:

```
specs/arquivo.md:linha — regra N — "trecho curto" — sugestão de reescrita
```

Agrupe por arquivo. Se não houver nenhum achado, retorne apenas `OK`.
