# Migração de deploy

Plano para levar o deploy atual ao [deploy padrão da wbrain](deploy.md). A execução é do tutor e fica fora do onboarding.

- Status: proposto | em andamento | concluído

## Deploy atual
Resumo; detalhes em [deploy.md](deploy.md) ou na seção do deploy atual.

## Compatibilidade

| Item do checklist | Situação | Como resolver | Quem |
|---|---|---|---|
| Roda via compose com healthchecks | ok \| falha | <ação> | agente \| tutor |
| Cabe numa única instância EC2 | | | |
| Pode usar AWS, SSM e Terraform | | | |
| Dados persistentes no volume ou externos | | | |
| Migrations no boot | | | |
| Sem serviços de plataforma | | | |
| Variáveis num único secret | | | |

## Dados
<o que precisa ser migrado (banco, arquivos), como e com que janela>

## Virada
1. Subir um ambiente de staging (`environment` diferente de `prod`) e validar.
2. <passos da virada: secrets, dados, DNS>
- Janela e comunicação: <...>

## Rollback
<como voltar ao deploy atual e até quando ele fica disponível>

## Responsáveis
- <passo>: <pessoa>
