# Testes visuais e jornadas E2E

[← Testes](testing.md)

Camada de testes de navegador com `@playwright/test` (TypeScript). Processo para o agente: [Validação visual](../guidelines/visual-validation.md).

## Como funciona

- O navegador roda num **Playwright server remoto** (container fora do projeto), indicado por `PW_TEST_CONNECT_WS_ENDPOINT`. O `@playwright/test` lê a variável (e `PW_TEST_CONNECT_EXPOSE_NETWORK`, `PW_TEST_CONNECT_HEADERS`): não há código de conexão.
- `PLAYWRIGHT_VERSION` (variável do ambiente) indica a versão do Playwright disponível no servidor: o `@playwright/test` do cliente usa **exatamente** essa versão. Antes de instalar ou atualizar o cliente, leia a variável.
- `PW_TEST_CONNECT_EXPOSE_NETWORK=*` usa a rede do cliente (túnel): o app é acessado por nome do compose (ex.: `http://nginx:2381`).
- O cliente é o serviço `e2e` do compose (perfil `e2e`), código em `src-frontend/e2e/`, `node_modules` em volume nomeado. Nada é instalado no host.
- Cobre hoje apps **sem backend** (showcase). **Pendências:** autenticação e dados de teste para apps com backend; `make e2e` com backend e banco de teste.

## Comandos

| Comando | Uso |
|---|---|
| `make screenshot route=/acoes/botao [theme=dark\|light] [density=comfortable\|compact] [size=<nome> \| sizes=all\|mobile,wide] [lang=pt-BR] [name=pasta] [viewport-only=1]` | Captura direta de uma rota. Padrões: tema `dark`, densidade `comfortable`, tamanho `laptop`, `pt-BR`, página inteira |
| `make screenshot flow=<nome>` | Roteiro: `tests/visual/flows/<nome>.spec.ts` (versionado) ou `temp/flows/<nome>.spec.ts` (descartável). Aceita `size=`/`sizes=` |
| `make visual [filter=<trecho da rota>]` | Matriz de todas as páginas × tema × tamanho (centenas de imagens: só em revisão ampla ou com `filter`) |
| `make e2e [grep=<texto>]` | Jornadas (passa/falha, código de saída ≠ 0) |
| `make e2e-install` | Instala as dependências do cliente no volume |
| `make e2e-version-check` | Conecta e avisa se a versão do cliente difere da do servidor |

## Saída

`./temp/screenshot/<nome>/<tamanho>-<largura>-NN-<passo>.png`; cada execução substitui só os arquivos do mesmo tamanho na pasta. O comando imprime os caminhos relativos ao host. Relatório HTML e traces em `./temp/report` e `./temp/test-results`.

## Sinais (fixture automática)

Reprovam o teste: erro de JS (`pageerror`), `console.error`, requisição falha (ignorando `ERR_ABORTED`) e overflow horizontal. Valem para visual e jornadas. **Não** cobrem layout, contraste nem foco.

## Tamanhos

Cada um é um *project* do Playwright: mobile 375×812, tablet 768×1024, small 1024×768, laptop 1280×800, desktop 1536×864, wide 1920×1080 (pontos de quebra do Tailwind).

## Estrutura

```
src-frontend/e2e/
  package.json            @playwright/test (versão EXATA do servidor), @types/node, typescript
  tsconfig.json
  playwright.config.ts    projects visual-<tamanho>, matrix, journeys; outputDir/report em /temp
  fixtures.ts             opções theme/density/lang; fixtures open, shot, signals (auto), setup (auto)
  tests/visual/page.spec.ts      captura de UMA rota (parâmetros SHOT_*)
  tests/visual/matrix.spec.ts    todas as páginas × tema × tamanho
  tests/visual/flows/*.spec.ts   roteiros versionados
  tests/journeys/*.spec.ts       jornadas E2E
  tests/scratch/                 montagem de ./temp/flows (no .gitignore)
```

Esqueletos de referência (a adaptar; copie removendo `.example`): `skills/shared/templates/e2e/`. Adapte rotas, chaves de `localStorage` (tema/densidade/idioma), host do nginx e porta ao projeto.

## Roteiro visual

```ts
import { test, expect } from "../../fixtures"
test.use({ theme: "dark", density: "comfortable", viewport: { width: 375, height: 812 } })

test("dialog", async ({ page, open, shot }) => {
  await open("/sobreposicoes/dialog")
  await shot("pagina-dialog")
  await page.getByRole("button", { name: "Indicar alguém" }).click()
  await expect(page.getByRole("dialog")).toBeVisible() // esperas por expect, nunca por timeout
  await shot("dialog-aberto")
})
```

Use `getByRole`/`getByLabel`, nunca classes CSS; um roteiro conta uma história curta; importe sempre de `../../fixtures`.

## Jornadas E2E

- Só **fluxos macros** cujo defeito o usuário percebe e o negócio perde.
- **Toda jornada é ligada a um snap:** primeira linha `// snap: snaps/<caminho>.md`.
- **Criar uma jornada exige aprovação do tutor.** Se cabe num teste unitário, não é jornada.
- Ficam em `tests/journeys/`, rodam com `make e2e` e usam as mesmas fixtures (inclusive sinais). Login e dados de teste entram como fixtures quando houver backend.
- Mantenha um **molde** curto (ex.: o tema escolhido sobrevive a recarregar a página).

## Armadilhas

Lista completa e diagnóstico por erro (428, 403, `ERR_SSL_PROTOCOL_ERROR`, DNS): `ambiente-docker.md` da skill, seção 4. Resumo: versão exata do cliente = servidor; `extra_hosts` para o servidor Playwright; `allowedHosts` do Vite; `||` (não `??`) em variáveis vazias; `addInitScript` só define se não existir; `reducedMotion: "reduce"` e `document.fonts.ready`; ESLint desliga `rules-of-hooks` só em `e2e/**`; `temp/` criado pelo Makefile e serviço `e2e` como root (ou `chmod -R a+rwX temp`, atalho de dev).
