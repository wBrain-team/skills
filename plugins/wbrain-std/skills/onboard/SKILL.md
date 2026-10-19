---
name: onboard
description: Traz um projeto existente para o fluxo wbrain-std — investiga o repositório com subagentes, entrevista o tutor, mede a distância até o padrão STD e, conforme o caso, entrega um relatório de bloqueios ou executa os ajustes (harness, docs, Docker, estrutura de testes e specs iniciais). Use apenas quando o usuário pedir explicitamente para fazer o onboarding wbrain-std de um projeto existente.
disable-model-invocation: true
---

# wbrain-std:onboard

Skill da série **wbrain-std** — STD = **Spec-Test-Driven**, a técnica da wbrain para desenvolvimento com IA: o `specs/` (mantido por humanos) é a fonte da verdade, e a implementação avança em TDD estrito a partir dele.

A `wbrain-std:init` cria projetos novos e a `wbrain-std:loop` implementa mudanças a partir do diff de `specs/`. Esta skill fica entre as duas: pega um projeto **que já existe** e o deixa pronto para o loop. Ela mede a distância até o padrão STD e decide a rota:
- **distante**: documenta os principais problemas e o que precisa ser feito, e devolve o trabalho ao tutor;
- **próximo ou intermediário**: planeja e executa os ajustes, com aprovação do tutor.

Siga as etapas **na ordem**. Fale com o usuário em pt-BR.

## Referências

Caminhos relativos à pasta desta skill (`${CLAUDE_PLUGIN_ROOT}/skills/onboard/`):
- `rubric.md`: régua de aderência usada no diagnóstico.
- `templates/state.md`: modelo do arquivo de estado.
- `templates/report.md`: modelo do relatório de onboarding.
- `templates/docker-migration.md`: modelo do plano de migração para Docker.
- `templates/deploy-migration.md`: modelo do plano de migração de deploy.
- `../init/template/`: **o padrão STD** (AGENTS.md, CLAUDE.md, `docs/`, `specs/specs.md`, `deploy/`, `gitignore`). É o modelo para o qual o projeto deve convergir.
- `../loop/spec-lint.md`: regras de escrita das specs.
- `../loop/templates/plan-summary.md`: formato enxuto de apresentação de plano.
- `../loop/scripts/check-doc-links.sh`: verificação de links internos.

## Regras transversais (valem em todas as etapas)

### Subagentes e contexto
- O agente principal **orquestra e conversa**; subagentes fazem a leitura pesada do repositório para poupar contexto.
- Cada subagente recebe uma tarefa **pequena, objetiva e autocontida**, com todo o contexto necessário no prompt (ele não vê esta conversa).
- Todo prompt de subagente exige um **retorno enxuto em formato fixo**: bullets, até ~30 linhas, sem colar código. Para apontar trechos, `caminho:linha` ou `caminho:início-fim`; para o arquivo todo, só o caminho.
- Dispare em paralelo (uma única mensagem) os subagentes independentes.

### Condução da conversa
- **Uma pergunta por vez**, aberta, em diálogo. Aprofunde com perguntas de seguimento quando a resposta abrir algo relevante.
- Pergunte **a partir do que foi descoberto**, não no vazio: "Vi X em `caminho`. É isso mesmo? Por quê?".
- **Fallback de baixa colaboração:** se o tutor der respostas curtas ou vagas (uma ou poucas palavras, "não sei", "tanto faz", "pode ser") em duas perguntas, passe a usar a ferramenta `AskUserQuestion` com opções de múltipla escolha. Quando houver uma opção alinhada ao padrão STD, ela vem primeiro, marcada como "(Recomendado)". O tutor sempre pode responder "Outro" com texto livre.

### Propor, explicar, respeitar a decisão
O objetivo é aproximar o projeto do modelo do init (estrutura de `docs/`, guidelines, práticas de TDD, Docker, Makefile), **respeitando as restrições reais do projeto**.
- Cada proposta de convergência é apresentada **uma de cada vez**: o que existe hoje, o que o padrão STD recomenda e **por que** (o benefício para o fluxo STD ou para o trabalho do agente).
- O tutor pode discordar e defender a prática atual. O agente pode contra-argumentar **uma vez**, com fatos. A **palavra final é sempre do tutor**.
- Divergência mantida pelo tutor vira ADR em `docs/decisions/` com as razões dele. Proposta aceita entra no plano.

### Limites do que a skill altera
- Mexe só em harness (`AGENTS.md`, `CLAUDE.md`, `.claude/`), `docs/`, `specs/`, infraestrutura (Docker, compose, Makefile, `.env.example`, `.gitignore`) e estrutura de testes. **Não altera código de negócio.** Se Docker ou testes exigirem ajuste no código (ex.: ler config de variável de ambiente), proponha e só faça com aprovação explícita.
- **Nunca toque em produção**: nada de deploy, alteração de CI/CD de deploy, DNS, secrets reais ou recursos de nuvem. O máximo é deixar arquivos e planos prontos; a execução é do tutor.
- Nada destrutivo (apagar, sobrescrever, mover) sem confirmação. Antes de sobrescrever, leia o alvo.
- Commits seguem a **política de commits** combinada na entrevista (camada 4) e registrada no estado. Sem política definida, não commite. Nunca faça push sem pedido nem commite na `main`.

### Estado (`.std/onboard/state.md`)
- Use o modelo em `templates/state.md`. Atualize ao fim de cada etapa e a cada decisão do tutor. Ele é a memória do onboarding; o contexto da conversa não é.
- Mantenha-o enxuto: resumos, decisões e caminhos, nunca código ou saídas longas.
- Garanta `.std/` no `.gitignore` assim que criar o arquivo.

## 0. Guardas

Rode na raiz do repositório:

```bash
git rev-parse --show-toplevel && git rev-parse --abbrev-ref HEAD && git log -1 --oneline
ls -A1 | grep -vxE '\.git|\.claude|\.claude-config|\.DS_Store|Thumbs\.db|desktop\.ini'
```

- Não é repositório git, ou não há commits → **recuse e encerre**: o onboarding precisa de histórico para que nada se perca. Oriente o tutor a versionar o projeto primeiro.
- Listagem vazia (pasta limpa) → **recuse e encerre** e indique a `wbrain-std:init`.
- Branch `main` (ou `master`) ou HEAD destacado → **recuse e encerre**. Sugira criar uma branch como `chore/std-onboard`. Só crie a branch se o tutor pedir **explicitamente**, com o nome definido.
- Alterações locais não commitadas → avise e peça que o tutor commite ou guarde antes de seguir.
- `.std/onboard/state.md` existe → leia e **retome** da etapa registrada, sem refazer o que já foi decidido. Se `status: concluído`, informe que o onboarding já foi feito e que o próximo passo é a `wbrain-std:loop`.

## 1. Descoberta (subagentes Explore, em paralelo)

Dispare até **4** subagentes `Explore`, um por foco:

- **(a) Stack e estrutura**: linguagens, frameworks e versões; monorepo ou não; pastas principais; como o projeto roda hoje (scripts, Makefile, `package.json`, `pyproject.toml` etc.); principais módulos de negócio.
- **(b) Harness e documentação**: `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.cursor/`, `.cursorrules`, `.github/copilot-instructions.md`, `.windsurfrules`, `docs/`, ADRs, READMEs, wikis no repositório, `specs/` ou equivalentes (PRDs, user stories). Para cada um: o que cobre, se está atualizado em relação ao código e se mistura assuntos.
- **(c) Testes e qualidade**: existe suíte? framework, quantidade aproximada, áreas cobertas e descobertas, como rodar, se roda em container; lint, formatter, CI (`.github/workflows`, `.gitlab-ci.yml` etc.).
- **(d) Infraestrutura e dependências**: Dockerfile e compose (o que sobe e o que fica de fora); variáveis de ambiente e onde são lidas; serviços externos (bancos gerenciados, filas, APIs de terceiros, SaaS, storage, autenticação externa), marcando o que **não** pode ser reproduzido localmente; como é o deploy atual.

Retorno exigido de cada um: bullets com caminhos, até ~30 linhas, terminando com uma seção **"Dúvidas para o tutor"** (o que o código não responde).

## 2. Diagnóstico

Com os retornos da etapa 1, classifique cada dimensão de `rubric.md` (`ok`, `ajuste` ou `bloqueio`) e chegue ao **veredito global** (próximo, intermediário ou distante) pelas regras de `rubric.md`. Registre no estado.

Apresente ao tutor um resumo curto (uma linha por dimensão, mais o veredito provisório) e diga que a entrevista vai confirmar ou corrigir esse quadro. O veredito só é fechado depois da entrevista.

## 3. Entrevista

Objetivo: entender a visão original do projeto, como ele é desenvolvido e mantido, e confirmar ou corrigir o diagnóstico. Siga as regras de **Condução da conversa**. Progressiva, **do negócio para o técnico**, uma camada por vez; pule ou condense o que a descoberta já respondeu com clareza.

1. **Negócio e visão** — o que é; que problema resolve; para quem; valor principal; a visão original de quem criou.
2. **Usuários e jornadas** — perfis; fluxos principais; idioma(s) do conteúdo.
3. **Funcionalidades existentes** — o que está em produção e é usado; o que está incompleto ou experimental; o que é código morto. Confronte com o que a descoberta encontrou. Isso define o escopo das specs (etapa 9).
4. **Desenvolvimento e manutenção** — quem mantém; fluxo de git e de revisão; CI; frequência de deploy; se já é desenvolvido com IA e qual harness usa (e o que funciona ou não nele).
   - **Política de commits do onboarding** (pergunta obrigatória): pergunte se o tutor quer que o agente faça commits ao longo das adequações ou como prefere que seja feito (ex.: um commit por tarefa do plano, um commit por área, um único commit no fim, ou nenhum, deixando tudo para ele revisar). Pergunte também sobre convenção de mensagem, se o projeto não usa Conventional Commits. Registre a resposta no estado.
5. **Stack** — confirme a stack real. Para cada camada (backend e dados, autenticação, frontend, testes), leia o doc correspondente em `../init/template/docs/` e aponte **só** as diferenças que valem a conversa, seguindo **Propor, explicar, respeitar a decisão**. Não proponha reescrever a aplicação: trocar framework ou linguagem fica fora do escopo.
6. **Dependências externas** — para cada serviço que o agente não consegue ver ou rodar: o que faz, se há sandbox, ambiente de teste ou credenciais de desenvolvimento, se pode ser emulado em container (ex.: LocalStack, MinIO, Mailpit) ou mockado nos testes, e quem pode resolver.
7. **Docker** — se ainda não roda em Docker, o que impede; o que precisa subir junto (banco, filas, workers).
8. **Deploy** — confirme como o deploy funciona hoje (onde roda, CI/CD, secrets, banco gerenciado, domínios, rollback) e se está satisfeito com ele. Aplique o checklist de compatibilidade da etapa 7 e apresente o resultado. Depois, ofereça as rotas da etapa 7, com a recomendação e o porquê. O deploy **não** é condição para o STD: manter o atual é sempre uma resposta válida.

Ao final, apresente um **resumo** (visão, funcionalidades existentes, decisões por camada, dependências externas e veredito revisado) e peça confirmação. Ajuste até o tutor confirmar. Registre no estado.

## 4. Decisão de rota

**Distante** → não tente adequar à força.
- Gere `docs/std-onboarding.md` a partir de `templates/report.md`: os principais problemas, por que cada um impede o fluxo STD, o que precisa ser feito e **quem faz** (agente ou tutor), em ordem de prioridade.
- Faça só os ajustes seguros, se o tutor aprovar: `.std/` no `.gitignore` e um `AGENTS.md` mínimo apontando para o relatório.
- Registre `status: bloqueado (aguardando tutor)` e encerre explicando que, resolvidos os bloqueios, a skill pode ser invocada de novo e retoma pelo estado.

**Próximo ou intermediário** → monte o **plano de adequação**: tarefas pequenas por área (harness, docs, Docker, testes, specs), cada uma com o que muda, o motivo e quem faz. Apresente no formato enxuto de `../loop/templates/plan-summary.md` (adaptado: sem a relação spec → teste), grave as tarefas como checkboxes no estado, registre `status: aguardando aprovação` e **pare**.
- **Seguir** → `status: em andamento`, vá para a etapa 5.
- **Ajuste** → aplique **Propor, explicar, respeitar a decisão**, refaça o plano e apresente de novo.

As etapas 5 a 9 seguem o plano aprovado. Marque cada checkbox ao concluir.

## 5. Harness e documentação

- **Harness.** Copie `AGENTS.md` e `CLAUDE.md` de `../init/template/` sem alterar. Se já existirem com outro conteúdo, mostre a diferença, proponha mover as instruções próprias do projeto para `docs/` e só substitua com confirmação. O mesmo vale para harness de outras ferramentas (`.cursorrules`, `copilot-instructions.md` etc.): o conteúdo útil vai para `docs/`; o arquivo original fica, vira um ponteiro para `AGENTS.md` ou é removido, conforme o tutor decidir. Crie `.claude/settings.json` a partir de `template/claude/settings.json` só se não existir. Garanta `.std/` no `.gitignore`.
- **Estrutura de `docs/`.** Convirja para a estrutura do template: `docs/docs.md` como índice, uma pasta por área com índice de mesmo nome (`guidelines/`, `stack/`, `backend/`, `auth/`, `frontend/`, `testing/`, `decisions/`), arquivos curtos e focados, links **Veja também**. Áreas que não existem no projeto ficam de fora.
- **Conteúdo.** Os docs descrevem o **projeto real**, não o template:
  - guias genéricos do template que valem para o projeto (ex.: `guidelines/tdd.md`, `git.md`, `agent-behavior.md`, `clean-code.md`) são copiados e ajustados ao que foi decidido;
  - guias de stack e camada são reescritos a partir da descoberta, seguindo a estrutura e o nível de detalhe do equivalente no template;
  - documentação existente é migrada e reorganizada, sem perder informação útil, e removida da origem só com confirmação;
  - não deixe docs descrevendo tecnologia ou prática que o projeto não usa.
- **ADRs.** Crie `docs/decisions/decisions.md` e um ADR (formato e numeração de `template/docs/decisions/`) para cada divergência relevante do padrão que o tutor manteve, com as razões dele, e para cada convergência relevante adotada.
- **README.** Garanta a seção "Onde está cada coisa" e os comandos reais de setup, no espírito de `template/README.md`, preservando o conteúdo atual útil.

## 6. Docker

O fluxo STD exige que tudo rode em containers (desenvolvimento e testes). Esta etapa trata do ambiente de desenvolvimento e testes; produção fica na etapa 7.

- **Já roda em Docker** → confira se dev e testes sobem pelo compose, com healthchecks e `.env.example`, e proponha só os ajustes que faltam.
- **Não roda em Docker** → preencha `templates/docker-migration.md` em `docs/stack/docker-migration.md`: serviços, dependências externas e como cada uma será tratada (container, emulador, mock ou pendência do tutor), passos em ordem e quem executa cada um.
  - **Viável para o agente** (dependências visíveis e reproduzíveis em container, ou mockáveis): com aprovação, execute a migração. Se há testes, eles devem passar no Docker antes de dar a etapa como concluída. Compare com o resultado fora do Docker quando possível.
  - **Não viável** (dependências opacas, credenciais ou ambientes que o agente não acessa, complexidade alta): o plano fica documentado e os itens viram **pendências do tutor** no relatório. Execute só a parte que não depende delas.
- Atualize `docs/stack/infrastructure.md` e `docs/stack/makefile.md` com o que ficou valendo.

## 7. Deploy

O deploy é uma trilha **separada e opcional**: o loop depende de specs, testes e Docker, não do deploy. Trocar o deploy de um projeto em produção é a mudança mais arriscada do onboarding (dados, DNS, secrets, indisponibilidade), por isso ela nunca é executada aqui.

**Checklist de compatibilidade com o deploy da init** (`../init/template/deploy/CONTRACT.md` e `../init/template/docs/stack/deploy.md`):
- roda via compose (hoje ou após a etapa 6), com healthchecks;
- cabe numa única instância EC2 (sem cluster, autoscaling ou múltiplas regiões);
- pode usar AWS, SSM e Terraform;
- dados persistentes cabem no volume da instância (`/ext-vol/`), ou ficam num serviço externo que continua externo;
- migrations rodam no boot do serviço;
- não depende de serviços de plataforma (Lambda, ECS, Kubernetes, Vercel, Heroku e afins);
- variáveis de ambiente podem vir de um único secret (`.env`).

**Rotas** (decisão do tutor, registrada no estado):
- **Manter o deploy atual** — padrão quando ele funciona. Documente-o em `docs/stack/deploy.md` (onde roda, como dispara, secrets, rollback, quem opera) e crie um ADR com as razões. Não copie `deploy/`.
- **Adotar o deploy da init** — só se o checklist passar. Copie `../init/template/deploy/` e `docs/stack/deploy.md`, adapte `deploy/config/config.yaml.example` como na etapa de adaptação da `wbrain-std:init` (sem alterar scripts nem Terraform; nunca crie `deploy/config/config.yaml`) e garanta o que o `CONTRACT.md` exige (`docker-compose.prod.yml`, `.env.example`). O primeiro deploy e a virada ficam com o tutor, de preferência validando antes num ambiente de staging (`environment` diferente de `prod`).
- **Migrar depois** — o projeto é parcialmente compatível, ou o tutor quer adotar, mas não agora. Documente o deploy atual (como em "manter") e preencha `templates/deploy-migration.md` em `docs/stack/deploy-migration.md`: itens do checklist que falham e como resolver, estratégia de virada, rollback e responsáveis. A execução fica fora do onboarding.

Em qualquer rota, o relatório lista o que o tutor precisa fazer.

## 8. Estrutura de testes

O loop depende de TDD: precisa de um jeito confiável de escrever e rodar testes pontuais e a suíte completa.

- **Projeto com testes** → documente como rodá-los (via Docker) em `docs/testing/`, no modelo de `template/docs/testing/`, e ajuste os comandos do Makefile (`make test` e teste pontual). Se há testes quebrados, registre no relatório; não os corrija nem apague sem aprovação.
- **Projeto sem testes automáticos** → **não invente testes** para o código existente. Proponha ações ao tutor (ex.: testes de caracterização das regras mais críticas, por prioridade) e registre como sugestão no relatório; o tutor decide se e quando.
- **Em todos os casos**, proponha e, com aprovação, crie a **estrutura mínima** para que as próximas features nasçam testadas:
  - runner configurado e rodando no container;
  - `make test` (suíte) e um comando de teste pontual (um arquivo ou um teste);
  - banco de teste isolado, se houver banco (ver `template/docs/testing/test-database.md`);
  - pastas e convenções de fixtures e factories;
  - **um teste de fumaça** que só prova que a infraestrutura de testes funciona.
- Registre em `docs/testing/` e `docs/stack/makefile.md`.

## 9. Specs (exceção de bootstrap)

Pelo `AGENTS.md`, agentes nunca modificam `specs/`. Esta etapa é a **única exceção**: o projeto ainda não tem fonte da verdade e precisa de uma base mínima para o tutor seguir pelo loop. O agente redige, mas **só grava um arquivo depois que o tutor aprova o conteúdo dele**. Terminado o onboarding, `specs/` volta a ser exclusivamente humano.

Se já existir `specs/` (ou documentação equivalente encontrada na etapa 1), parta dela: reorganize e complete em vez de reescrever, com a mesma regra de aprovação.

1. **Mapa de specs.** Dispare um subagente `Plan` com o resumo da entrevista (funcionalidades existentes, usuários, jornadas) e os retornos da descoberta. Ele propõe a árvore de arquivos a partir de `specs/specs.md`, seguindo `../loop/spec-lint.md`: um assunto por arquivo (cada fluxo de negócio, cada componente relevante), herança `Extends` quando houver base comum, termos do glossário do projeto. Retorno: a árvore com uma linha por arquivo descrevendo o assunto, mais "Dúvidas para o tutor". Apresente o mapa ao tutor e ajuste até aprovar. Registre no estado.
2. **Um documento por vez**, na ordem do mapa (raiz e glossário primeiro):
   - dispare um subagente `Explore` para levantar o comportamento **atual** daquele assunto no código e nos testes: regras, validações, casos de borda, erros e permissões, com `caminho:linha`;
   - redija a spec seguindo **todas** as regras de `spec-lint.md`: presente, sem passado, sem futuro, comportamento testável com números, o quê e não como, termos consistentes, fonte única com links, casos de borda explícitos, sem `TODO`;
   - confira o rascunho contra `spec-lint.md` antes de mostrar;
   - apresente ao tutor e pergunte o que for preciso, **sem deixar ambiguidade**: regras que o código não deixa claras, comportamentos que parecem bug, termos com mais de um sentido;
   - grave o arquivo só após a aprovação e marque-o no estado.
3. **Realidade, não intenção.** A spec descreve **o que a aplicação faz hoje**.
   - Se o tutor disser que algo "deveria ser diferente" ou "vai mudar", isso **não** entra na spec: registre na seção **Gaps** do relatório, como futura mudança de spec a ser feita pelo tutor e implementada pelo loop.
   - Se o código parecer ter um bug, pergunte. Se o tutor confirmar que é bug, a spec descreve o comportamento correto e o bug vai para **Gaps**. Caso contrário, a spec descreve o comportamento atual.
4. **Escopo mínimo.** Especifique o necessário para o tutor continuar pelo loop: as funcionalidades em produção e as áreas que ele pretende mexer primeiro. Áreas não especificadas ficam listadas no relatório.
5. Garanta que toda spec é alcançável a partir de `specs/specs.md`.

## 10. Verificação e relatório

- Rode `../loop/scripts/check-doc-links.sh docs specs` (caminho relativo a esta skill) e corrija os links quebrados.
- Dispare um subagente `Explore` para um lint final de **todas** as specs criadas, com `../loop/spec-lint.md`, no formato de retorno do guia. Achados → corrija com o tutor (cada correção aprovada por ele).
- Se há Docker, rode a suíte via Docker uma vez (`make test` ou equivalente) e registre o resultado. Se `deploy/` foi copiado, rode `bash deploy/tests/config-test.sh` (só valida a configuração; não faz deploy).
- Atualize `docs/std-onboarding.md` (modelo `templates/report.md`) com: veredito por dimensão antes e depois, o que foi feito, ADRs criados, **pendências do tutor**, **Gaps** e áreas sem spec.
- Registre `status: concluído` no estado (ou `bloqueado`, se sobraram pendências que impedem o loop).
- Se a política combinada prevê commit no fim, faça-o agora; caso contrário, confira que o que foi commitado bate com a política.
- Relatório final ao tutor, curto: o que mudou por área, pendências dele e o próximo passo — revisar (e commitar, se ainda não estiver commitada) a base (harness, docs, specs) e integrá-la à `main`, para que a `wbrain-std:loop` passe a trabalhar a partir do diff de `specs/`.
