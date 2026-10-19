---
name: wbrain-std-init
description: Inicializa um novo projeto a partir do boilerplate wbrain-std numa pasta vazia — entrevista o usuário sobre o projeto, copia a base (README, AGENTS, docs, specs) e a adapta às respostas. Use apenas quando o usuário pedir explicitamente para iniciar/criar um projeto com o boilerplate wbrain.
disable-model-invocation: true
---

# wbrain-std-init

Skill da série **wbrain-std** — STD = **Spec-Test-Driven**, a técnica da wbrain para desenvolvimento com IA: o `specs/` (mantido por humanos) é a fonte da verdade, e a implementação avança em TDD estrito a partir dele. Esta skill prepara o terreno para esse fluxo.

Gera a base inicial de um projeto a partir do snapshot em `template/` (nesta pasta da skill) e adapta o conteúdo ao projeto do usuário.

Siga as etapas **na ordem**. Fale com o usuário em pt-BR.

## 1. Guarda de base limpa (obrigatória)

Esta skill só roda numa pasta limpa, para nunca sobrescrever arquivos importantes.

Rode na raiz do projeto (diretório de trabalho atual):

```bash
ls -A1 | grep -vxE '\.git|\.claude|\.claude-config|\.DS_Store|Thumbs\.db|desktop\.ini'
```

- Saída vazia → base limpa, siga em frente.
- Qualquer saída → **recuse e encerre**. Liste os itens encontrados e explique que a skill só roda numa pasta vazia (são tolerados apenas `.git/`, `.claude/`, `.claude-config/` e arquivos de sistema como `.DS_Store`). **Não** ofereça sobrescrever, mesclar, mover ou apagar arquivos, nem prossiga com a entrevista, mesmo que o usuário insista — ele deve limpar a pasta por conta própria e invocar a skill de novo.

## 2. Entrevista

Objetivo: entender o projeto o suficiente para adaptar os docs e pré-popular o README.

Regras de condução:
- **Uma pergunta por vez**, em diálogo. Prefira perguntas **abertas** que convidem o usuário a dar detalhes; aprofunde com perguntas de seguimento quando a resposta abrir algo relevante.
- **Progressiva, uma camada por vez, do negócio para o técnico.** Não comece pela tecnologia e não despeje a stack inteira de uma vez.
- Ao entrar em cada camada técnica, leia o doc correspondente em `template/docs/` e apresente **só o padrão daquela camada**, de forma curta, perguntando se mantém ou ajusta. "Manter o padrão" é sempre uma resposta válida.
- Pule ou condense camadas que as respostas anteriores já definiram (ex.: "é só uma API" → sem camada de frontend).
- **Fallback de baixa colaboração:** se o usuário der respostas curtas ou vagas (uma ou poucas palavras, "não sei", "tanto faz", "pode ser") em duas perguntas, passe a usar a ferramenta `AskUserQuestion` com opções de múltipla escolha para cobrir o que falta. Nas camadas técnicas, a primeira opção é sempre "Manter o padrão (Recomendado)". O usuário sempre pode responder "Outro" com texto livre.

Camadas, nesta ordem:

1. **Negócio** — nome do projeto; o que é; que problema resolve; para quem; qual o valor principal.
2. **Usuários e uso** — perfis de usuário; principais jornadas/fluxos; idioma(s) do conteúdo.
3. **Visão de curto prazo** — o que é o MVP; primeiras funcionalidades; integrações externas; prazos ou marcos.
4. **Backend e dados** — padrão em `template/docs/stack/technologies.md` (seção Backend) e `template/docs/backend/database.md`.
5. **Autenticação** — padrão em `template/docs/auth/auth.md`.
6. **Frontend** — padrão em `template/docs/frontend/frontend.md` e `template/docs/stack/technologies.md` (seção Frontend). Pergunte também se o projeto terá frontend.
7. **Infraestrutura** — padrão em `template/docs/stack/infrastructure.md`.
8. **Deploy** — padrão em `template/docs/stack/deploy.md` (EC2 na AWS via SSM + Terraform, já incluso em `template/deploy/`). Pergunte primeiro se o projeto será implantado na AWS com esse fluxo; se sim, colete o que já se sabe: `environment` (padrão `prod`), região AWS (padrão `sa-east-1`), repositório git no formato `git@host:org/repo.git` e branch, bucket S3 do state do Terraform (se já existe) e se terá HTTPS público (domínios e e-mail de contato). Para o `name` de recursos, proponha o nome do projeto em minúsculas com hífens. "Preencher depois" é válido para qualquer item.

Ao final, apresente um **resumo** do que entendeu (negócio, visão, e por camada: "padrão" ou a mudança) e peça confirmação. Ajuste até o usuário confirmar.

## 3. Cópia da base

Refaça a checagem da etapa 1 imediatamente antes de copiar (se algo apareceu, recuse e encerre). Então, sendo `SKILL_DIR` a pasta desta skill:

```bash
cp -R "$SKILL_DIR/template/." .
mv gitignore .gitignore
mkdir -p .claude
[ -e .claude/settings.json ] || cp claude/settings.json .claude/settings.json
rm -rf claude
[ -d deploy ] && find deploy -name '*.sh' -exec chmod +x {} +
```

Os `.sh` de `template/deploy/` ficam sem permissão de execução (modo `644`) dentro da skill, de propósito. Por isso o `chmod +x` acima é obrigatório após a cópia: sem ele, `make deploy` falha com `Permission denied`. Se o projeto já for um repositório git, registre também o modo no índice (`git update-index --chmod=+x` nos mesmos arquivos) para o ajuste ser versionado.

## 4. Adaptação

Edite os arquivos copiados conforme a entrevista:

- **`README.md`** — título com o nome do projeto; parágrafo de abertura com o que é, para quem e o problema que resolve; seção curta "Visão de curto prazo" com o MVP e as primeiras funcionalidades; ajuste pré-requisitos, comandos e URLs se a stack/infra mudou. Mantenha a seção "Onde está cada coisa".
- **Stack** — reflita as mudanças em `docs/stack/technologies.md`, `infrastructure.md`, `folder-structure.md` e `makefile.md`.
- **Áreas descartadas** — se uma camada não existe no projeto (ex.: sem frontend, sem auth), remova a pasta de docs correspondente e todas as referências a ela (índices como `docs/docs.md`, `docs/testing/testing.md`, links em **Veja também**).
- **Áreas alteradas** — ajuste os docs da camada para a nova escolha; não deixe docs descrevendo tecnologia que não será usada.
- **ADRs** — para cada mudança relevante de stack em relação ao padrão, crie um ADR em `docs/decisions/` seguindo o formato e a numeração dos existentes, e registre-o em `docs/decisions/decisions.md`.
- **Deploy** — adapte `deploy/config/config.yaml.example` (nunca crie `deploy/config/config.yaml`, que guarda dados do ambiente e não é versionado) com as respostas da camada 8: `name` (só minúsculas, dígitos e hífen), `environment`, `state` (bucket/key/region; a `key` segue `<name>/<environment>/terraform.tfstate`), `deploy.repo`/`deploy.branch` e o bloco `https` (com `enabled: true` só se houver domínios). Região diferente de `sa-east-1` → ajuste também `aws_region` em `deploy/config/terraform.tfvars.example`. Itens sem resposta ficam com os placeholders. Se o projeto não usará esse deploy, trate como área descartada: remova `deploy/`, `docs/stack/deploy.md` e as referências (`docs/stack/stack.md`, `infrastructure.md`, `folder-structure.md`, `docs/docs.md`, `README.md`). Não altere os scripts nem o Terraform de `deploy/`.
- **Idioma** — se o conteúdo do produto não for pt-BR, ajuste o locale padrão citado em `docs/frontend/i18n.md`.
- **`specs/specs.md`** — é a fonte da verdade mantida por humanos: **não** escreva requisitos nele. Só se o usuário pedir explicitamente, ofereça um rascunho com o que foi coletado, deixando claro que cabe a ele revisar.
- **`CLAUDE.md` e `AGENTS.md`** — mantenha inalterados.

## 5. Verificação e relatório

- Confira que nenhum link interno aponta para arquivo inexistente:
  ```bash
  grep -rnoE '\]\([^)#]+\.md' --include='*.md' . | grep -v '^./.claude' 
  ```
  e verifique cada destino (relativo ao arquivo de origem). Corrija os quebrados.
- Se `deploy/` foi mantido, confira que o exemplo adaptado ainda é válido: `bash deploy/tests/config-test.sh`.
- Reporte ao usuário: o que foi copiado, o que foi adaptado (por arquivo), o que foi removido, ADRs criados e sugestões de próximos passos (ex.: preencher `specs/specs.md`). Se `deploy/` foi mantido, inclua os passos do primeiro deploy (seção "Primeiro deploy" de `docs/stack/deploy.md`), lembrando que o projeto ainda precisa criar o `docker-compose.prod.yml` e o `.env.example` exigidos por `deploy/CONTRACT.md`.
- Não faça commit, a menos que o usuário peça.
