# ADR-0001 — Código em inglês; idioma do conteúdo livre

[← Decisões](decisions.md)

- **Status:** Aceito
- **Data:** 2026-10-13

## Contexto

Os exemplos misturavam identificadores em português (`UserRole.ADMINISTRADOR`, rotas
`/usuarios`) e em inglês, e o seed exigia dados fake em inglês sem que o resto do
projeto seguisse essa regra.

## Decisão

Todo código é escrito em inglês: variáveis, funções, classes, arquivos, tabelas,
colunas, enums, rotas, chaves de tradução, migrations e branches. O idioma do conteúdo
(textos de interface, mensagens, dados fake, comentários, documentação) é livre.

## Consequências

- Identificadores consistentes, independentes do idioma da equipe ou do produto.
- Textos de interface passam sempre pelo i18n, o que facilita adicionar idiomas.
- Regra em [Clean Code](../guidelines/clean-code.md#idioma).
