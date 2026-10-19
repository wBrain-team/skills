# Estilização — Tailwind CSS + Shadcn/UI

[← Frontend](frontend.md)

**Princípios:**
- Shadcn/UI é a fonte primária de componentes — não construa do zero o que o Shadcn já oferece.
- Componentes Shadcn vivem em `packages/ui/src/components/ui/` e pertencem ao projeto — podem e devem ser modificados. Dentro de `@design-system/ui` use **imports relativos** (nunca o alias `@/`, que pertence a cada app).
- Tailwind **v4** (CSS-first) é usado para layout, espaçamento, tipografia e customizações sobre os componentes Shadcn.
- Tema (cores, raios, fontes) centralizado nas CSS variables OKLCH do `globals.css` (blocos `@theme inline` + `:root`/`.dark`) — nunca hardcode valores de cor ou tamanho inline. Não há mais `tailwind.config.ts`/preset; o plugin `@tailwindcss/vite` faz o build.
- Modo escuro via `class` strategy (`dark:` prefix) — o toggle de tema alterna a classe `dark` no `<html>`.
- Ícones exclusivamente via `@remixicon/react` (Remix Icon) — não misture bibliotecas de ícones.

## Estrutura de componentes

```
packages/ui/src/components/
├── ui/              # Componentes Shadcn (modificáveis)
│   ├── button.tsx
│   ├── dialog.tsx
│   └── ...
└── common/          # Componentes reutilizáveis compostos sobre ui/
    ├── PageHeader.tsx
    ├── DataList.tsx
    ├── KpiCard.tsx
    └── ...

apps/<app>/src/components/features/   # Componentes específicos de domínio (por app)
├── auth/
└── users/
```

Componentes específicos de um domínio (ex.: `features/auth/`) vivem **dentro do app**.
Componentes genéricos e reutilizáveis entre apps vivem em **`@design-system/ui`**. Ao adicionar
um export novo em `@design-system/ui`, registre-o no `packages/ui/src/index.ts`.

## Adicionando componentes Shadcn

Novos componentes são adicionados ao pacote `@design-system/ui` via CLI dentro do container —
nunca instalados manualmente:

```bash
make shadcn component=dialog
```

Após gerar, ajuste os imports internos para caminhos relativos e exporte no `index.ts`.

## Exemplo de composição correta

```tsx
// Compõe sobre Shadcn, customiza com Tailwind — não recria do zero
import { useTranslation } from "react-i18next"
import {
  Button, Dialog, DialogClose, DialogContent, DialogFooter, DialogHeader, DialogTitle,
} from "@design-system/ui"
import { RiDeleteBinLine } from "@remixicon/react"

export function DeleteConfirmDialog({ onConfirm }: { onConfirm: () => void }) {
  const { t } = useTranslation()
  return (
    <Dialog>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>{t("common.delete_confirm.title")}</DialogTitle>
        </DialogHeader>
        <p className="text-sm text-muted-foreground">{t("common.delete_confirm.description")}</p>
        <DialogFooter>
          <DialogClose asChild>
            <Button variant="outline">{t("common.cancel")}</Button>
          </DialogClose>
          <Button variant="destructive" onClick={onConfirm}>
            <RiDeleteBinLine className="mr-2 h-4 w-4" />
            {t("common.delete")}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
```

Nos **apps**, componentes do design system são importados sempre de `@design-system/ui`
(nunca de `@/components/ui/...`, que não existe no app). O alias `@/` aponta para o
`src/` do próprio app (ex.: `@/lib/axios`, `@/store/auth.store`).

---

**Veja também:** [Estrutura](structure.md) · [Layout de páginas](page-layout.md)
