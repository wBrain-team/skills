---
name: loop
description: Executa o ciclo de implementação de uma modificação (feature, ajuste de regra, refactor ou remoção) a partir do que mudou em `specs/` — descobre o contexto com subagentes, planeja em TDD, implementa, atualiza `docs/` e valida com a suíte completa no final. Use apenas quando o usuário pedir explicitamente para rodar o loop wbrain-std.
disable-model-invocation: true
---

# wbrain-std:loop

Skill da série **wbrain-std** — STD = **Spec-Test-Driven**, a técnica da wbrain para desenvolvimento com IA: o `specs/` (mantido pelo tutor humano, com ajuda das skills `onboard` e `spec`) é a fonte da verdade, e a implementação avança em TDD estrito a partir dele.

Esta skill implementa uma **modificação**: nova feature, novo recurso, ajuste de comportamento ou regra de negócio, refactor técnico ou remoção. O escopo é **exatamente** o que houver de novo em `specs/`.

Siga as etapas **na ordem**. Fale com o usuário em pt-BR. Leia `AGENTS.md` antes de começar.

## Regras transversais (valem em todas as etapas)

### Subagentes e contexto
Siga `${CLAUDE_PLUGIN_ROOT}/skills/shared/subagentes.md`.

### Guarda de ambiguidade (classifica; só o bloqueante interrompe o loop)
Fique atento a ambiguidades em todas as etapas: instruções que não fazem sentido, que admitem mais de uma leitura, que conflitam com outra spec ou com `docs/`, ou que não trazem as informações necessárias para uma implementação robusta.

Para cada uma, classifique antes de agir. **O padrão é seguir em frente**: a spec é a fonte da verdade, mas o agente deve ser colaborativo, usar bom senso e o contexto para preencher lacunas, e reservar o bloqueio para o que realmente não dá para decidir sozinho. Há três classes.

**1. Tolerável (siga e registre como premissa)** — a leitura mais provável é clara pelo contexto (resto da spec, pai/filhas `Extends:`, outras specs, `docs/`, código atual, padrões de funcionalidades equivalentes), **ou** as leituras possíveis diferem só em detalhe menor, fácil de ajustar depois.

Exemplos: erro de digitação ou nome parecido com termo/campo/rota já definido; sinônimo por descuido; link ou referência cruzada imprecisa com alvo óbvio; detalhe omitido que `docs/` ou funcionalidades equivalentes já definem (paginação, ordenação, mensagens, formatos, validações comuns); redação vaga com critério em outro trecho; tempo verbal ou estilo; divergência de forma entre spec e `docs/`; lacuna de caso de borda comum que o padrão do projeto já resolve.

**2. A confirmar (siga até o plano e peça validação na etapa 6)** — há uma leitura **mais razoável**, apoiada em evidência do contexto, mas as alternativas teriam comportamento observável diferente. Não pare. Planeje com a leitura adotada e, na etapa 6, destaque o item com a alternativa descartada: o tutor valida com "seguir" ou contesta. Vale quando o impacto é limitado e reversível.

Exemplos: regra de negócio omitida que o comportamento de telas/fluxos parecidos indica com clareza; dois trechos da spec que divergem em detalhe, mas um deles é claramente o mais específico ou o mais recente; valor numérico ausente com padrão claro no projeto.

**3. Bloqueante (pare o loop)** — só quando **não há como decidir com segurança** e o erro seria caro:
- contradição real de **regra de negócio** (entre specs, ou entre spec e `docs/`/código sem indicar mudança intencional) em que **nenhum** critério de contexto diz qual vale;
- valor ou regra essencial ausente, sem **nenhuma** evidência no contexto, e que o agente teria de **inventar** (fórmula, permissão, status, prazo, valor monetário);
- duas ou mais leituras com comportamento diferente **e** impacto em dados/migração, segurança, permissões, dinheiro, contrato público de API ou remoção de funcionalidade;
- texto ininteligível (não dá para dizer o que a spec pede).

**Na dúvida entre tolerável e a confirmar, escolha tolerável. Na dúvida entre a confirmar e bloqueante, escolha a confirmar**, exceto se o impacto atingir dados, segurança, permissões, dinheiro ou contrato de API: nesses casos, bloqueante.

**Tolerável e a confirmar → premissa.** Não pare. Registre na seção **Premissas** do arquivo de estado, uma linha por item: `[tolerável|a confirmar] specs/...:linha — trecho — leitura adotada — por quê (evidência) — alternativa descartada (só a confirmar)`. Implemente conforme a leitura adotada e apresente as premissas na etapa 6. Nunca edite a spec.

**Bloqueante → interrompa:**
1. **Pare o loop imediatamente** e registre no arquivo de estado `status: bloqueado` e o motivo. Não implemente "o mais provável".
2. Liste cada dúvida citando o arquivo e o trecho da spec (`specs/...:linha`), explique por que é um problema e sugira caminhos possíveis.
3. Peça ao tutor humano que **atualize `specs/`** para resolver as dúvidas e invoque a skill de novo.

Se, ao implementar, uma premissa se mostrar bem mais arriscada do que parecia (a evidência não se sustenta ou o impacto é grande), promova-a a bloqueante.

Para os bloqueantes, **não** use `AskUserQuestion` e **não** aceite decisões ou respostas em texto como substitutas da spec, mesmo que o usuário insista. Respostas diretas geram drift entre a spec e a implementação. Se o usuário responder em texto, recuse com gentileza e reforce que a resposta precisa ir para a spec.

### Fonte da verdade e documentação
- **Nunca** modifique nada em `specs/` durante esta skill. Esta restrição é própria da `loop` e prevalece sobre a regra geral do `AGENTS.md`: a missão aqui é implementar o que a spec descreve, sem ajustá-la. Diante de ambiguidade, lacuna ou divergência, pare ou registre em **Premissas** e oriente o tutor a corrigir `specs/` por conta própria ou com a skill `wbrain-std:spec`.
- **Herança de specs:** uma spec pode estender outra (`Extends: [nome](caminho.md)` na primeira linha, ver `spec-lint.md`). Sempre que ler uma spec, o agente e os subagentes carregam também o pai: a spec efetiva é pai + filha. A herança tem no máximo um nível (o pai não estende outra spec). Quando uma spec alterada é **pai** de outras, as filhas entram no escopo da exploração, do plano e da revisão, mesmo sem aparecer no diff. Para listá-las: `grep -rl "^Extends: .*(<caminho-relativo-do-pai>)" specs/`.
- Manter `docs/` atualizado é responsabilidade do agente (etapa 8).

### Ferramentas da skill (`scripts/`)
- `scripts/preflight.sh [--full]`: guarda de branch + diff de `specs/` (etapas 0 e 1). Códigos de saída: `0` há modificação, `1` recusado/erro, `3` nada a implementar.
- `scripts/check-doc-links.sh [caminho...]`: lista links internos quebrados em `docs/` e `specs/` (etapas 2 e 8).
- `scripts/spec-coverage.sh [spec...]`: relaciona specs aos testes pelo marcador `spec:` (etapas 7 e 10). Convenção em `../shared/rastreabilidade.md`.

- `../shared/spec-lint.md`: regras de escrita das specs, usadas no lint da etapa 2.
- `review.md`: guia do subagente revisor (etapa 10).
- `templates/state.md` e `templates/plan-summary.md`: modelos do arquivo de estado e do resumo de aprovação do plano.
- `preflight.sh --base <ref>`: compara contra outra base (ex.: commit de conclusão do loop anterior); a saída inclui `fingerprint` e o caminho do arquivo de `state`.

Os caminhos são relativos à pasta desta skill (`${CLAUDE_PLUGIN_ROOT}/skills/loop/`).

### Estado do loop (`.std/loop/<branch>.md`)
Cada branch tem um arquivo de estado, cujo caminho o `preflight.sh` informa na linha `state:`. A pasta `.std/` fica fora do git (`.gitignore`). O arquivo permite retomar um loop interrompido e auditar o que foi feito.

Use o modelo em `templates/state.md`. Preencha os campos de status conforme o momento; os que não se aplicam ficam vazios.

- Atualize o arquivo **ao fim de cada etapa e de cada tarefa** do plano. Ele é a memória do loop; o contexto da conversa não é.
- Mantenha-o enxuto: resumos e caminhos, nunca código ou saídas longas.

### Testes
- Escreva e rode os testes **seguindo as guidelines**: `docs/guidelines/tdd.md`, `docs/testing/` (a partir de `testing.md`) e `docs/guidelines/agent-behavior.md`. Isso inclui rodar via Docker, nunca instalar dependências na máquina local e seguir os padrões de fixtures/factories e de isolamento do banco.
- **Durante a implementação**, rode só testes **pontuais, restritos e enxutos**: um arquivo ou um teste específico, com os comandos de `docs/stack/makefile.md` e `docs/testing/`.
- **Nunca** rode a suíte completa antes da etapa 9, para não gastar CPU e memória à toa.
- **Testes sempre em série:** nunca rode duas execuções de teste ao mesmo tempo (agentes diferentes compartilham o Docker e o banco de teste). Só o principal, ou um único subagente por vez, roda testes.

### Limites de tentativas
- **Mesmo teste pontual:** até **10** tentativas de correção dentro de uma tarefa.
- **Suíte completa:** até **5** rodadas de correção (incluindo as que vêm da revisão na etapa 10).

Ao atingir um limite: pare, registre `status: bloqueado` no arquivo de estado e reporte ao tutor o que foi tentado, a falha atual e as hipóteses. O tutor pode pedir que o agente **continue tentando** (vale um novo ciclo do mesmo limite) ou dar **orientações técnicas** sobre a implementação. Essa é a única exceção à regra de não aceitar respostas em texto: se a orientação mudar comportamento ou regra de negócio, ela precisa ir para a spec. Registre a orientação no arquivo de estado.

## 0. Guarda de branch (obrigatória)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/loop/scripts/preflight.sh
```

O script cobre esta etapa e a próxima.

- Se ele sair com código `1` (branch `main`, HEAD destacado ou `main` inexistente) → **recuse e encerre**. Explique que rodar o loop na `main` é arriscado demais e oriente o usuário a criar uma branch, sugerindo um nome no padrão de `docs/guidelines/git.md` (`feat/<descrição>`, `fix/<descrição>`, `chore/<descrição>`). Outra opção é o usuário pedir **explicitamente** que o agente crie uma branch com nome definido. Depois disso, ele invoca a skill de novo.
- **Nunca** crie uma branch por conta própria e não prossiga na `main`, mesmo que o usuário insista sem indicar a branch.

## 1. Estado e diff da spec

**Retomada.** Se o preflight indicar `state: ... (existe)`, leia o arquivo de estado e decida:
- `status: concluído` → o loop anterior terminou. Rode `preflight.sh --base <commit de conclusão>` para ver só o que mudou depois dele. Se houver mudança, comece um loop novo no mesmo arquivo: mova o resumo do loop anterior para **Histórico** e reinicie os demais campos.
- Qualquer outro status, com **fingerprint igual** ao atual → a spec não mudou. Retome da etapa e da tarefa pendentes, sem refazer descoberta nem plano. Se estava `bloqueado`, o bloqueio continua: reapresente-o e encerre. Se estava `aguardando aprovação`, reapresente o plano (etapa 6).
- Qualquer outro status, com **fingerprint diferente** → a spec mudou desde o plano. Recomece a partir da etapa 2 com a mesma base. Na etapa 5, informe ao subagente `Plan` as tarefas já concluídas (e o código que já existe) para ele não refazê-las.

Sem arquivo de estado → crie-o com `status: em andamento`, a base e o fingerprint.

**Diff.** A saída do `preflight.sh` lista os arquivos alterados em `specs/` (commitados na branch contra a `main`, alterações locais e não rastreados), com status e estatística. Para ler o conteúdo das mudanças, rode `preflight.sh --full` (ou `git diff <base> -- <arquivo>` para um arquivo só).

- Código `3` (sem nenhuma alteração) → informe que não há modificação a implementar e **encerre**.
- Com alterações → resuma a modificação para uso interno: o que é **novo**, o que foi **alterado** e o que foi **removido**, e quais camadas parecem afetadas. Aplique a guarda de ambiguidade já aqui, se for o caso.

**Trilha.** Classifique a modificação e registre `trilha: curta|normal — <motivo>` no arquivo de estado. É **curta** só se **todos** os critérios valem:
- toca 1 ou 2 arquivos de spec, sem arquivo novo, removido ou renomeado;
- não altera linha `Extends:` e nenhum arquivo alterado é pai de outras specs;
- não envolve dados/migração, segurança, permissões, dinheiro nem contrato público de API;
- afeta uma camada só.

**Na dúvida, normal.** A trilha curta reduz a cerimônia das etapas 2 a 6 (veja a nota "Trilha curta" em cada uma); as etapas 7 a 11 são iguais nas duas trilhas, e a aprovação do plano continua obrigatória. Se em qualquer etapa a modificação se mostrar maior do que parecia (outra camada, um dos critérios acima, mais de 3 tarefas), **promova para normal**: registre no estado e refaça a partir da etapa 3, aproveitando o que já foi descoberto.

## 2. Lint da spec (bloqueante)

Antes de gastar subagentes com exploração, verifique se **as mudanças** nas specs estão bem escritas. O lint vale **só para o diff**: problemas antigos em trechos não alterados ficam fora. O agente **não corrige** a spec; só aponta o problema e sugere a reescrita ao tutor humano.

1. Rode `bash ${CLAUDE_PLUGIN_ROOT}/skills/loop/scripts/check-doc-links.sh <arquivos>` passando só os arquivos de spec adicionados ou modificados, para achar links e `extends` quebrados neles.
2. Dispare **um subagente `Explore`** com: a base do preflight, a lista de arquivos alterados e a instrução de rodar `preflight.sh --full --base <base>` para ver o diff, ler `${CLAUDE_PLUGIN_ROOT}/skills/shared/spec-lint.md` e consultar os arquivos alterados, o pai deles (`Extends:`) e, se algum for pai, as filhas. Os arquivos completos, o pai e as filhas entram só como contexto; o lint vale para as linhas adicionadas ou alteradas. Para as regras de termos, duplicação e órfãs, o subagente consulta as demais specs só no necessário. Retorno exigido no formato definido em `spec-lint.md`.

**Trilha curta:** sem subagente. Rode o passo 1 e o próprio principal lê o diff (`preflight.sh --full`) contra `spec-lint.md`, com o mesmo formato de retorno e os mesmos critérios.

Cada achado vem classificado como **bloqueante** ou **observação** (critérios em `spec-lint.md` e na guarda de ambiguidade). O lint é um **apoio à qualidade da spec, não um portão rígido**: a regra é tratar como observação e só bloquear o que impede de saber o que implementar. Link ou `extends` quebrado cujo alvo correto é óbvio é observação; alvo inexistente ou indeterminável é bloqueante.

- Se houver **qualquer achado bloqueante** → **pare o loop**. Apresente os bloqueantes agrupados por arquivo, cada um com a regra violada e a sugestão de reescrita, e peça ao tutor que corrija `specs/` e invoque a skill de novo. Valem as mesmas regras da guarda de ambiguidade: não aceite respostas em texto e nunca edite a spec. Registre o bloqueio no arquivo de estado (`status: bloqueado`). Inclua as observações na mesma mensagem, para o tutor corrigir tudo de uma vez.
- Se houver **só observações** → não pare. Registre-as na seção **Premissas** do arquivo de estado (com a leitura adotada, quando houver) e siga. Elas aparecem na etapa 6.

## 3. Estado atual da aplicação (subagentes Explore, um por camada)

Pelo diff, escolha **só as camadas afetadas** e dispare **um subagente `Explore` por camada**, em paralelo:
- **backend**: rotas, serviços, repositórios, schemas;
- **banco**: models, migrations, seed;
- **frontend**: páginas, componentes, estado, cliente de API;
- **jobs/integrações**: workers e serviços externos;
- **infra/config**: Docker, variáveis de ambiente, Makefile.

Se a mudança for pequena e de uma camada só, dispare um único subagente. Teto de ~4.

**Trilha curta:** um único subagente `Explore`, da camada afetada, que cobre também a etapa 4 (os docs relacionados entram no mesmo retorno).

Cada subagente cobre o código **e os testes da sua camada** (não há subagente só de testes). Prompt: o resumo da modificação + a camada. Retorno exigido:
- arquivos/módulos relevantes (com `caminho:linha` quando couber);
- comportamento atual relacionado à modificação;
- testes que já cobrem a área;
- lacunas (regras sem teste, código morto, inconsistências);
- pontos de contato com outras camadas.

## 4. Docs relacionados (subagente Explore)

**Trilha curta:** coberta pelo subagente da etapa 3.

Dispare (em paralelo com a etapa 3) um subagente `Explore` que parte de `docs/docs.md` e procura o que já está registrado sobre o assunto. Retorno exigido:
- guias e ADRs aplicáveis (caminhos);
- regras obrigatórias para esta modificação (TDD, camadas, contrato de API, exceções, migrations etc.);
- conflitos ou divergências entre `docs/` e a spec;
- docs que provavelmente precisarão ser atualizados.

Depois das etapas 3 e 4, **aplique a guarda de ambiguidade** (só o que for bloqueante para; o tolerável vira premissa).

## 5. Plano de ação (subagente Plan)

**Trilha curta:** sem subagente. O principal escreve de 1 a 3 tarefas seguindo os mesmos critérios abaixo (TDD, marcador `spec:`, docs, comando de teste pontual, dúvidas). Mais de 3 tarefas → promova para normal.

Dispare um subagente `Plan` com o resumo do diff e os retornos das etapas 3 e 4. O plano deve:
- seguir as instruções de `docs/`, em especial **TDD**: para cada item, o teste vem antes da implementação;
- garantir testes **úteis e valiosos**, centrados nas **regras de negócio**, para que implementações futuras não causem regressão;
- em remoções, prever a retirada do código **e dos testes** obsoletos;
- incluir a atualização de `docs/` (o que criar, atualizar ou remover);
- dividir o trabalho em tarefas pequenas, marcando quais são **paralelizáveis** (arquivos disjuntos) e quais são **sequenciais**;
- indicar, por tarefa, o **comando de teste pontual** que valida o progresso;
- terminar com a seção **"Dúvidas/ambiguidades"**, separando **bloqueantes** de **premissas** (toleráveis, com a leitura adotada). Se houver bloqueantes → **guarda de ambiguidade**. As premissas seguem para a etapa 6.

Retorno exigido: o plano em lista numerada, enxuto, com `caminho:linha` quando couber. Grave as tarefas na seção **Plano** do arquivo de estado, como checkboxes. Peça ao subagente também a relação **mudança na spec → teste(s) que a garantem**, usada na etapa 6. Esses testes levam o marcador `spec:` (ver `${CLAUDE_PLUGIN_ROOT}/skills/shared/rastreabilidade.md`); em remoções, a relação inclui os testes marcados com a spec removida.

## 6. Aprovação do plano (sempre)

Antes de implementar, apresente o plano ao tutor e **pare**, aguardando a resposta. Registre `status: aguardando aprovação`. A apresentação é enxuta, para ser revisada em 1 ou 2 minutos. Use o modelo em `templates/plan-summary.md` (na trilha curta, a variante curta do mesmo arquivo). As respostas possíveis são as mesmas nas duas trilhas.

O resumo inclui as **premissas** assumidas, para o tutor conferir: as **a confirmar** em destaque, com a alternativa descartada, e as **toleráveis** em lista curta. Nenhuma bloqueia, mas o tutor pode contestá-las. Recomende ao tutor corrigir a redação na spec depois, sem urgência.

O plano completo fica no arquivo de estado para quem quiser abrir. A resposta é **binária**:
- **Seguir** → (as premissas também ficam aceitas) registre `plano aprovado: <data>` e `status: em andamento`, e vá para a etapa 7.
- **Discordância de comportamento** (entendimento errado, regra faltando ou a mais, ou premissa contestada) → **guarda de ambiguidade**: a correção vai para `specs/`, e o loop recomeça pelo fingerprint novo.
- **Discordância técnica** (abordagem, biblioteca, estrutura) → não é assunto da spec. Registre a orientação em `docs/` (guideline no guia temático ou ADR em `docs/decisions/`), mostre ao tutor o que foi registrado e volte à etapa 5 para replanejar com base nos docs atualizados. Nunca guarde a orientação só no chat.
- Resposta que não seja nenhuma dessas → peça que o tutor diga se segue, ou qual o tipo de ajuste.

Ao retomar com o mesmo fingerprint e o plano já aprovado, não pergunte de novo.

## 7. Implementação

Ciclo por tarefa: **teste vermelho → implementação mínima → teste verde → refactor**, rodando só os testes pontuais da tarefa. Todo teste de regra de negócio nasce com o marcador `spec:`.

**Tarefas sequenciais:** o agente principal implementa, ou dispara um único subagente `general-purpose` que pode rodar os testes pontuais da tarefa.

**Tarefas paralelizáveis:** edição em paralelo, testes em série. Para cada lote:
1. **Testes:** dispare um subagente `general-purpose` por tarefa, em paralelo, com `isolation: "worktree"`, para escrever **só os testes**, sem rodá-los. Ao final, o principal integra os worktrees na branch e roda os testes pontuais de cada tarefa, um por vez, confirmando que **falham** (vermelho).
2. **Implementação:** dispare de novo um subagente por tarefa, em paralelo e em worktree, para escrever a implementação, sem rodar testes. O principal integra e roda os testes pontuais, um por vez, até ficarem **verdes**.
3. Conflito na integração → resolva se for trivial; senão, refaça a tarefa de forma sequencial.

O prompt de cada subagente traz a tarefa, os arquivos envolvidos, as regras de `docs/` aplicáveis, o comando de teste pontual e se ele pode ou não rodar testes. Nunca dois subagentes no mesmo arquivo. Retorno exigido: arquivos alterados, testes rodados e resultado (se rodou), pendências ou dúvidas.
- Ao concluir cada tarefa, marque o checkbox no arquivo de estado e registre o resultado do teste pontual.
- Se surgir uma ambiguidade durante a implementação → **guarda de ambiguidade** (classifique: tolerável vira premissa, bloqueante para).

## 8. Documentação

Ao longo da implementação (ao fim de cada tarefa ou grupo de tarefas), revise `docs/` e registre, atualize, altere ou remova o que for relevante, criando novos arquivos se for preciso:
- mantenha os índices (`docs/docs.md` e o índice de cada pasta) e os links **Veja também** coerentes;
- para decisões técnicas relevantes, crie um ADR em `docs/decisions/` no formato e na numeração dos existentes e registre-o em `docs/decisions/decisions.md`;
- não deixe docs descrevendo comportamento que não existe mais;
- ao terminar, rode `scripts/check-doc-links.sh` e corrija os links quebrados.

## 9. Validação final

Só agora, com tudo implementado, rode a **suíte completa** uma única vez (`make test`, mais os testes de frontend se existirem) e o lint (`make lint`).
- Se algo falhar → corrija usando testes pontuais e rode a suíte completa de novo só no fim. Respeite o limite de 5 rodadas.

## 10. Revisão independente (subagente revisor)

Dispare um subagente `general-purpose` **somente leitura** (instrua-o a não editar arquivos nem fazer commits) com: a base do preflight, o resumo da modificação, o plano do arquivo de estado e a instrução de seguir `${CLAUDE_PLUGIN_ROOT}/skills/loop/review.md`. O revisor compara o diff de `specs/` com o diff de código, testes e docs, e devolve os achados no formato do guia.

- Achados **bloqueantes** → corrija (testes pontuais), rode a suíte completa de novo e dispare **uma** nova revisão. Se ainda houver bloqueantes, pare e reporte ao tutor.
- Achados **sugestões** → aplique se forem baratos e dentro do escopo; senão, liste-os no relatório final.
- Se o revisor apontar ambiguidade ou conflito **bloqueante** na spec → **guarda de ambiguidade**. Observações de spec viram premissas no relatório final.

## 11. Commits e relatório

- Commite apenas na branch atual (nunca na `main`, salvo ordem explícita do tutor humano).
- Siga `docs/guidelines/git.md` (Conventional Commits: `<tipo>(escopo): descrição curta`). Faça commits granulares, um por tarefa coerente.
- Nunca use `--no-verify` e não faça push sem pedido.
- Ao terminar, atualize o arquivo de estado: `status: concluído` e `commit de conclusão: <hash do HEAD>`.
- Relatório final curto: o que mudou (por camada), testes criados/alterados e resultado da suíte, docs atualizados, commits feitos e **premissas assumidas** (com a sugestão de ajuste na spec para o tutor).
