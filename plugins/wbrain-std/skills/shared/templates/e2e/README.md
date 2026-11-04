# Esqueleto do cliente Playwright (referência)

Derivado de um projeto real (monorepo React + Vite atrás de nginx, em Docker) onde a conexão remota, as fixtures e os specs foram validados. Foi **generalizado** aqui: nomes de rota, chaves de `localStorage`, seletores e textos de botão são do app de origem e **precisam de adaptação** (`ADAPTAR` marca os pontos principais; confira também os specs molde). Não foram reexecutados depois da generalização: valide a conexão primeiro (`skills/shared/ambiente-docker.md`, seção 4.3).

Copie para `src-frontend/e2e/` removendo o sufixo `.example`.

- `package.json.example`: `@playwright/test` com versão **exata** do servidor (o `1.64.1` é só o exemplo do projeto de origem; sem `^`). Descubra a do servidor pelo erro 428 de uma conexão de teste.
- Tamanhos: o Makefile escolhe os projects (`--project=visual-<tamanho>`, `matrix`, `journeys`); `tests/scratch/` recebe o bind mount de `./temp/flows` (fica no `.gitignore`).
- ESLint: desligue `react-hooks/rules-of-hooks` só para `e2e/**` e configure `globals` de Node e navegador. Rode também `npx tsc --noEmit` em `e2e/`.
