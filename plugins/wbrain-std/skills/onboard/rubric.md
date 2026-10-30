# Régua de aderência STD

Usada no diagnóstico (etapa 2) para medir a distância entre o projeto e o padrão STD (`../init/template/`). Cada dimensão recebe um nível:

- **ok**: já atende, ou atende com ajustes triviais.
- **ajuste**: não atende, mas o agente consegue resolver com aprovação do tutor.
- **bloqueio**: não atende e depende do tutor (decisão, acesso, conhecimento ou trabalho que o agente não consegue fazer).

## Dimensões

| Dimensão | ok | ajuste | bloqueio |
|---|---|---|---|
| **Harness** | `AGENTS.md`/`CLAUDE.md` no padrão STD | Sem harness, ou harness de outra ferramenta a migrar | — |
| **Documentação** (`docs/`) | Estrutura e índices no modelo do template, coerente com o código | Docs espalhados, desatualizados ou inexistentes, mas o código é legível | Código ilegível ou sem ninguém que saiba explicar o projeto |
| **Snaps** | `snaps/` com raiz, um assunto por arquivo, no presente | Sem snaps, mas o tutor conhece o comportamento e responde à entrevista | Ninguém sabe dizer o que o sistema deve fazer |
| **Docker** | Dev e testes rodam via compose | Não roda em Docker, mas as dependências são reproduzíveis ou mockáveis | Depende de serviços, hardware ou ambientes que não podem ser reproduzidos nem mockados |
| **Testes** | Suíte roda via Docker, com teste pontual | Sem testes ou fora do Docker, mas dá para criar a estrutura mínima | Não há como rodar testes (ex.: só funciona em produção) |
| **Comandos** (Makefile) | `make` cobre subir, testes, lint | Comandos espalhados ou só documentados | — |
| **Dependências externas** | Todas visíveis, com sandbox ou mock | Algumas opacas, com caminho claro para o tutor resolver | Opacas, críticas e sem caminho conhecido |
| **Git** | Branch `main`, histórico, fluxo de branches | Convenções de commit ou branch fora do padrão | — |
| **Deploy** (informativa) | Deploy documentado: o da init, ou um próprio que o tutor mantém | Deploy não documentado, ou adoção/migração planejada | — |

## Veredito global

- **Próximo**: nenhum `bloqueio` e no máximo 3 `ajuste`.
- **Intermediário**: nenhum `bloqueio` em Docker, Testes ou Snaps, e os demais bloqueios têm caminho claro.
- **Distante**: qualquer `bloqueio` em Docker, Testes ou Snaps, ou bloqueios sem caminho claro. Sem essas três dimensões a tuning não funciona.

A dimensão **Deploy** é só informativa: aparece no diagnóstico e no relatório, mas não conta para o veredito (ver etapa 7 do `SKILL.md`).

O veredito é provisório até a entrevista (etapa 3) confirmar.
