# Migração para Docker

Plano para o projeto rodar em containers (desenvolvimento, testes e, se aplicável, produção), condição do fluxo STD. A meta de produção é atender o [contrato de deploy](../../deploy/CONTRACT.md), quando o deploy padrão for adotado.

- Executor: agente | tutor | misto
- Status: proposto | em andamento | concluído | bloqueado

## Como roda hoje
<processos, versões de runtime, serviços locais, scripts>

## Serviços no compose

| Serviço | Imagem/base | Função | Healthcheck | Dados persistentes |
|---|---|---|---|---|
| <app> | <imagem> | <função> | <comando> | <volume ou "—"> |

## Dependências externas

| Dependência | Uso | Tratamento | Quem resolve |
|---|---|---|---|
| <serviço> | <para quê> | container \| emulador (<qual>) \| mock nos testes \| pendência | agente \| tutor |

## Variáveis de ambiente
<chaves que vão para `.env.example` e onde são lidas>

## Passos

1. <passo> — quem: agente | tutor — validação: <como saber que deu certo>

## Riscos e pendências
- <risco ou pendência> — <mitigação>
