# wbrain skills

Marketplace de skills da wbrain para desenvolvimento.

## Instalação

### 1. Pré-requisitos

O repositório é privado. Antes de instalar:

- Peça acesso de leitura ao repositório `wBrain-team/skills`.
- Deixe o git autenticado na máquina: SSH configurado ou `gh auth login`.
- Opcional, para atualização automática em segundo plano: defina `GITHUB_TOKEN` (ou `GH_TOKEN`) com acesso de leitura ao repositório.

### 2. Adicionar o marketplace (uma vez)

No Claude Code:

```
/plugin marketplace add https://github.com/wBrain-team/skills.git
```

Se você usa SSH, prefira:

```
/plugin marketplace add git@github.com:wBrain-team/skills.git
```

O atalho `wBrain-team/skills` também funciona para repositórios do GitHub.

### 3. Instalar o plugin

```
/plugin install wbrain-std@wbrain
```

Ou use `/plugin`, abra a aba **Discover** e escolha `wbrain-std`. Depois da instalação, rode `/reload-plugins` se as skills não aparecerem.

### 4. Conferir

Digite `/wbrain-std:` e as cinco skills devem aparecer na lista.

### Atualizar e remover

```
/plugin marketplace update wbrain       # busca as versões novas
/plugin uninstall wbrain-std@wbrain     # remove o plugin
```

## Skills do plugin `wbrain-std`

Todas são de invocação manual (`disable-model-invocation`), no formato `/wbrain-std:<skill>`, por exemplo `/wbrain-std:init`.

| Skill | Uso |
|---|---|
| `init` | Inicializa um projeto a partir do template padrão |
| `spec` | Escrita de specs |
| `tuning` | Ajuste fino da aplicação guiado pelo diff de spec |
| `onboard` | Onboarding/migração de projetos existentes |
| `design-system` | Fundação do design system e desenho de componentes novos |

As skills dependem umas das outras (caminhos relativos), por isso são distribuídas juntas em um único plugin.

## Estrutura

```
.claude-plugin/marketplace.json     # catálogo
plugins/wbrain-std/
├── .claude-plugin/plugin.json
└── skills/{init,spec,tuning,onboard,design-system,shared}/
```

## Contribuindo

Veja [CONTRIBUTING.md](CONTRIBUTING.md).
