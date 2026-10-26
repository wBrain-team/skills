# Guia de escrita de snapshots

Cola para o agente consultar e citar ao orientar o tutor. As regras completas (e o que a tuning bloqueia) estão em `../shared/snapshot-lint.md`; este guia não as substitui.

## A ideia em uma frase
Um snapshot diz **o que a aplicação faz agora**, em um arquivo pequeno, com regras que um teste consegue verificar.

## Errado e certo

| Problema | ❌ Evite | ✅ Prefira |
|---|---|---|
| Passado (regra 1) | "Antes o desconto era 5%, agora é 10%." | "O desconto é de 10%." |
| Futuro (regra 2) | "Por enquanto sai em CSV; depois será PDF." | "O relatório é exportado em CSV." |
| Tempo verbal (regra 3) | "O sistema deverá abrir um menu." | "A aplicação abre o menu ao clicar em **Opções**." |
| Vago (regra 6) | "A busca deve ser rápida." | "A busca responde em até 500 ms e mostra 20 resultados por página." |
| Como, não o quê (regra 8) | "Criar a tabela `orders` e usar Celery." | "O cliente recebe um e-mail de confirmação em até 5 minutos." |
| Pendência (regra 9) | "Erros: a definir." | "Se o e-mail já existe, o cadastro é recusado com a mensagem 'E-mail já cadastrado'." |

## Esqueleto sugerido (adapte; não é obrigatório)

```markdown
Extends: [Lista base](../base/data-list.md)

# Lista de pedidos

Uma linha dizendo o que é e para quem.

## Comportamento
- Dado um cliente com pedidos, quando abre a lista, então vê 20 pedidos por página, do mais recente ao mais antigo.
- Sobrescreve: a lista mostra 50 itens por página.

## Casos de borda e erro
- Sem pedidos: mostra "Você ainda não fez pedidos".
- Falha ao carregar: mostra "Não foi possível carregar" e o botão **Tentar de novo**.

## Permissões
- Cliente vê só os próprios pedidos. Visitante é redirecionado ao login.

## Veja também
- [Frete](shipping.md)
```

Notas sobre o esqueleto:
- A linha `Extends:` só entra se o snapshot herda de outra, e fica sempre na **primeira linha**, sozinha.
- A linha `Sobrescreve:` só existe em snapshot filho, para cada regra do pai que ela muda.
- Os blocos `Casos de borda e erro`, `Permissões` e `Veja também` entram quando houver conteúdo real. Nunca como espaço reservado.

## Perguntas que destravam um snapshot em branco
- Qual é o uso mais simples possível, do começo ao fim?
- O que acontece quando dá errado?
- Quem não pode fazer isso?
- Qual é o número (limite, prazo, tamanho) por trás de "rápido", "muitos", "grande"?
- Existe outro snapshot que já define parte disso? (Então use um link.)

## Como organizar `snapshots/`

A árvore segue o modelo mental de quem conhece a aplicação: qualquer pessoa que conhece o sistema deve achar onde cada detalhe está descrito.

- **Domínio de negócio no primeiro nível.** Uma pasta por domínio (`pedidos/`, `catalogo/`, `faturamento/`), não por camada técnica (`frontend/`, `backend/`).
- **Um eixo dentro do domínio, escolhido por projeto:** telas (aplicação com interface), endpoints ou recursos (microsserviço de API), eventos ou jobs (workers e filas). O eixo escolhido fica declarado no topo de `snapshots/snapshots.md`.
- **A regra de negócio vive uma vez, no domínio.** Snapshots de tela e de endpoint apontam para ela com link em vez de repeti-la.
- **Transversais em pastas próprias:** `base/` (pais de `Extends`), `permissoes/`, e no frontend `componentes/`, com um snapshot por componente visual.
- **Nomes vêm do glossário.** Se o negócio diz "pedido", a pasta é `pedidos/`.
- **Teste de descoberta:** quem conhece o sistema chega à regra a partir do índice em até dois cliques.

## Árvore de exemplo

```
snapshots/
├── snapshots.md                 # índice: eixo de organização + links por domínio
├── base/
│   └── data-list.md         # comportamento comum das listas
├── componentes/
│   ├── header.md
│   └── date-picker.md
├── pedidos/
│   ├── pedidos.md           # índice do domínio
│   ├── regras.md            # regras de negócio do pedido
│   ├── lista.md             # tela; Extends: ../base/data-list.md
│   └── checkout.md          # tela; aponta para regras.md
└── contas/
    ├── contas.md
    └── cadastro.md
```

Num microsserviço, o mesmo domínio teria `pedidos/criar-pedido.md` e `pedidos/consultar-pedido.md` no lugar das telas.

## Lembretes
- Um termo para um conceito (não alterne "cliente", "usuário", "comprador").
- Cada regra vive em um só lugar; os outros snapshots apontam com link.
- Toda snapshot é alcançável a partir de `snapshots/snapshots.md`.
- Snapshot de implementação (ex.: refactor) começa com "Snapshot técnica: ..." e só então pode falar de como.
- Quem grava o snapshot é o tutor. O agente sugere no chat.
