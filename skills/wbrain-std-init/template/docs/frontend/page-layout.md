# Layout e componentes de página

[← Frontend](frontend.md)

## Layout de páginas — ocupar a largura disponível

Toda página ocupa **toda a largura** da área de conteúdo (`<main>` do `AppLayout`) e
alinha o conteúdo **à esquerda**. O cabeçalho (`PageHeader`) e os contêineres de
seção sempre se estendem por toda a largura — listagens, tabelas e cards acompanham.

**Nunca centralize a página inteira com `mx-auto max-w-*`.** Isso cria uma faixa
estreita centralizada que desperdiça espaço e desalinha o cabeçalho.

```tsx
// ✅ Correto — página em largura total, alinhada à esquerda
<div className="space-y-6">
  <PageHeader title={t("users.title")} actions={<Button>...</Button>} />
  <DataList ... />
</div>

// ❌ Errado — centraliza e estreita a página inteira
<div className="mx-auto max-w-2xl space-y-6">
  <PageHeader ... />
  ...
</div>
```

**Formulários estruturados ocupam a largura total.** Em vez de empilhar campos numa
coluna estreita, distribua-os num `Card` com grade responsiva (`grid sm:grid-cols-2`)
agrupada por seções. Assim o bloco preenche o espaço disponível sem margem morta à
direita e os campos se distribuem de forma eficiente — campos longos (nome) ocupam a
linha inteira (`sm:col-span-2`); pares relacionados (e-mail/telefone, papel/status) ficam
lado a lado. Veja o padrão em `UserForm`.

```tsx
<div className="space-y-6">
  <PageHeader title={t("users.new.title")} />
  <UserForm ... />   {/* o Card interno ocupa toda a largura */}
</div>
```

**Quando limitar a largura:** apenas conteúdo de coluna única que ficaria estranho
esticado (um texto corrido, ou a `<dl>` de uma tela de detalhe). Nesses casos use
`max-w-*` **sem `mx-auto`** (mantém à esquerda). Para formulários, prefira a grade em
largura total acima.

## Componentes de página padronizados

Para consistência entre telas, use sempre os componentes do `@design-system/ui` abaixo — não
recrie cabeçalhos nem barras de ação manualmente.

### Cabeçalho com breadcrumb — `PageHeader`

`PageHeader` exibe **apenas título** (sem descrição), com `breadcrumbs` e `actions?`
opcionais. Em telas internas (detalhe/edição), passe `breadcrumbs` para situar o
usuário. Para navegação SPA, passe `renderBreadcrumbLink` (helper
`@/lib/breadcrumb-link` que usa `<Link>`).

Regras do breadcrumb (`{ label, href?, icon? }`):
- O **primeiro item** é renderizado **apenas com o ícone** (sem texto) — use o mesmo
  ícone da seção no menu lateral. O `label` vira nome acessível (`sr-only`), então é
  obrigatório informá-lo.
- O **último item** é a página atual (sem link).

```tsx
import { RiTeamLine } from "@remixicon/react"

<PageHeader
  breadcrumbs={[
    { label: t("users.title"), href: "/users", icon: RiTeamLine }, // só o ícone
    { label: t("users.new.breadcrumb") },                          // página atual
  ]}
  renderBreadcrumbLink={renderBreadcrumbLink}
  title={t("users.new.title")}
/>
```

O componente `Breadcrumbs` (data-driven) também pode ser usado isoladamente quando
não houver um cabeçalho completo.

### Rodapé de formulário — `FormFooter`

**Nunca** use botões `w-full` em formulários (inclusive no login) nem em diálogos — nestes, use o `DialogFooter`. Envolva as ações em `FormFooter`: barra
com borda no topo e botões em tamanho natural, alinhados à direita (`align="end"`,
padrão). Use `align="between"` para separar uma ação destrutiva, e `sticky` quando o
formulário rola e o rodapé deve ficar fixo na base.

```tsx
<form onSubmit={...}>
  {/* campos */}
  <FormFooter>
    <Button variant="outline" type="button" onClick={onCancel}>{t("common.cancel")}</Button>
    <Button type="submit">{t("common.save")}</Button>
  </FormFooter>
</form>
```

---

**Veja também:** [Estrutura e qualidade de formulários](form-design.md) · [Acessibilidade](../guidelines/accessibility.md)
