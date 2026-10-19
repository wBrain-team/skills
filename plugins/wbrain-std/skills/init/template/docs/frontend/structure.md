# Estrutura — monorepo multi-app

[← Frontend](frontend.md)

O `src-frontend/` é um **monorepo (npm workspaces)** que suporta múltiplos frontends
compartilhando código. O design system vive no pacote `@design-system/ui` e é consumido pelos apps.

```
src-frontend/
├── package.json              # workspaces: ["packages/*", "apps/*"]
├── packages/
│   └── ui/                   # @design-system/ui — design system compartilhado
│       └── src/
│           ├── styles/globals.css     # tokens OKLCH (@theme inline + :root/.dark) — sem preset/config JS
│           ├── theme/                  # ThemeProvider + ThemeToggle
│           ├── components/ui/          # componentes Shadcn (modificáveis)
│           ├── components/common/      # DataList, KpiCard, StatusBadge, ...
│           └── index.ts                # barrel de exports públicos
└── apps/
    ├── web/                  # app real (nginx :8084)
    │   └── src/
    │       ├── components/
    │       │   ├── common/   # componentes reutilizáveis do app (ex.: SectionTitle)
    │       │   ├── features/ # componentes por domínio (auth/, users/, audit/)
    │       │   └── layout/   # AppLayout, Sidebar
    │       ├── pages/        # páginas/rotas
    │       ├── routes/       # guards de rota
    │       ├── store/        # estado global (Zustand)
    │       ├── services/     # chamadas à API (por domínio)
    │       ├── hooks/        # useListData, useAsyncOptions
    │       ├── lib/          # axios.ts, labels.ts, pagination.ts, utils, schemas/ (Zod)
    │       ├── types/        # tipos e interfaces globais
    │       └── tests/        # Vitest + React Testing Library
    └── design-system/        # showcase / referência viva (nginx :8085)
```

**Consumo nos apps:**

```ts
import { Button, DataList, ThemeToggle } from "@design-system/ui"
import "@design-system/ui/styles/globals.css"
```

> O **design system** (http://localhost:8085/) é a referência visual e de código.
> Antes de criar um componente novo, verifique se ele já existe em `@design-system/ui` e como
> deve se comportar/aparecer no showcase.

---

**Veja também:** [Estilização](styling.md) · [Utilitários do app](shared-utilities.md)
