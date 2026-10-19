# Guia de escrita de specs

Cola para o agente consultar e citar ao orientar o tutor. As regras completas (e o que o loop bloqueia) estão em `../wbrain-std-loop/spec-lint.md`; este guia não as substitui.

## A ideia em uma frase
Uma spec diz **o que a aplicação faz agora**, em um arquivo pequeno, com regras que um teste consegue verificar.

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
- A linha `Extends:` só entra se a spec herda de outra, e fica sempre na **primeira linha**, sozinha.
- A linha `Sobrescreve:` só existe em spec filha, para cada regra do pai que ela muda.
- Os blocos `Casos de borda e erro`, `Permissões` e `Veja também` entram quando houver conteúdo real. Nunca como espaço reservado.

## Perguntas que destravam uma spec em branco
- Qual é o uso mais simples possível, do começo ao fim?
- O que acontece quando dá errado?
- Quem não pode fazer isso?
- Qual é o número (limite, prazo, tamanho) por trás de "rápido", "muitos", "grande"?
- Existe outra spec que já define parte disso? (Então use um link.)

## Árvore de exemplo

```
specs/
├── specs.md                 # índice: links para todas as specs
├── base/
│   └── data-list.md         # comportamento comum das listas
└── frontend/
    ├── header.md
    ├── order-list.md        # Extends: ../base/data-list.md
    └── signup-form.md
```

## Lembretes
- Um termo para um conceito (não alterne "cliente", "usuário", "comprador").
- Cada regra vive em um só lugar; as outras specs apontam com link.
- Toda spec é alcançável a partir de `specs/specs.md`.
- Spec de implementação (ex.: refactor) começa com "Spec técnica: ..." e só então pode falar de como.
- Quem grava a spec é o tutor. O agente sugere no chat.
