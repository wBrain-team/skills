# Documentação

Ponto de partida da documentação de implementação e boas práticas. Cada pasta tem um
índice com o mesmo nome (ex.: `backend/backend.md`) que lista seus arquivos.

O que o produto faz — requisitos, modelo de dados e endpoints — está em
[snapshots/snapshots.md](../snapshots/snapshots.md), a fonte da verdade, mantida pelas pessoas (agentes só a
alteram com aprovação do tutor). Como rodar o projeto: [README.md](../README.md).

## Áreas

| Área | Conteúdo |
|---|---|
| [Diretrizes](guidelines/guidelines.md) | Comportamento do agente, TDD, clean code, acessibilidade, segurança, git |
| [Stack](stack/stack.md) | Tecnologias, infraestrutura (Docker/Nginx/ARM-x86), deploy na AWS, Makefile, estrutura de pastas |
| [Backend](backend/backend.md) | Camadas, exceções, contrato da API, config, banco, migrations, logging, audit log, jobs, seed |
| [Autenticação](auth/auth.md) | OTP por e-mail, JWT, RBAC, auth no frontend |
| [Frontend](frontend/frontend.md) | Monorepo, estilização, API, `DataList`, formulários, estado, i18n |
| [Testes](testing/testing.md) | Unitários, API, banco de teste, factories, frontend, cobertura |
| [Decisões](decisions/decisions.md) | ADRs: registro das decisões técnicas e suas razões |

## Essencial

- Siga o [comportamento do agente](guidelines/agent-behavior.md): leia antes de editar e peça confirmação antes de ações destrutivas ou que afetem produção.
- Desenvolva em [TDD](guidelines/tdd.md) estrito; ao finalizar uma feature, `make test-coverage` com services em 80%+ e, se tocou o frontend, `make test-coverage-front` com 80%+.
- Tudo roda em containers, acessado via Nginx na porta 8084 (ver [Infraestrutura](stack/infrastructure.md)).
- Código (identificadores, tabelas, colunas, rotas) sempre em inglês; o idioma do conteúdo é livre — ver [Clean Code](guidelines/clean-code.md#idioma).
- Commits em [Conventional Commits](guidelines/git.md).

## Manutenção

- Atualize a documentação junto com o código.
- Prefira arquivos curtos e focados num assunto: ao criar um, registre-o no índice da pasta e ligue-o aos assuntos relacionados em **Veja também**.
- Toda decisão técnica relevante (escolha de padrão, biblioteca ou trade-off) ganha um [ADR](decisions/decisions.md).
- Mudanças no passo a passo de setup atualizam o [README.md](../README.md).
- Divergência entre a implementação e o [snapshots](../snapshots/snapshots.md) não se resolve por conta própria: sinalize às pessoas responsáveis e só altere o snapshots com aprovação do tutor.
