# Estrutura e qualidade de formulários

[← Frontend](frontend.md)

Formulários devem ter aparência **profissional e fluida** — nunca uma pilha de campos
em coluna única ("cara de formulário preguiçoso de ERP"). Use `UserForm` como
referência. Diretrizes:

- **Agrupe em seções** com subtítulo curto (ex.: "Dados pessoais", "Acesso e
  permissões"), separadas por `Separator`, dentro de um `Card`.
- **Distribua em grade responsiva** (`grid sm:grid-cols-2`): campos longos (nome)
  ocupam a linha inteira (`sm:col-span-2`); campos relacionados ficam lado a lado.
  No mobile, a grade colapsa para uma coluna.
- O bloco do formulário ocupa **toda a largura** (sem `max-w` na página).

**Controles não-texto (switch, checkbox, radio):** não os envolva em uma caixa com
borda/fundo que imite um input — isso parece um "campo falso". Mantenha o controle
limpo, com o rótulo de estado ao lado, e alinhe a altura à dos inputs vizinhos
(`h-9`) quando estiverem na mesma linha da grade.

```tsx
// ✅ switch limpo, alinhado por altura ao select vizinho
<FormItem>
  <FormLabel>{t("users.fields.status")}</FormLabel>
  <div className="flex h-9 items-center gap-3">
    <FormControl>
      <Switch checked={field.value} onCheckedChange={field.onChange} aria-label={t("users.fields.status")} />
    </FormControl>
    <span className="text-sm font-medium">{field.value ? t("users.status.active") : t("users.status.inactive")}</span>
  </div>
</FormItem>

// ❌ box com borda imitando input — parece um campo que não é
<FormItem className="rounded-lg border p-4 ...">...</FormItem>
```

**Texto de ajuda (`FormDescription`):** use apenas para contexto **estável e
verdadeiro**. Não enumere uma única regra quando o sistema terá várias (ex.: listar só
uma das restrições de um papel induz ao erro) — nesses casos, **omita** a descrição em
vez de escrever algo que envelhece mal.

---

**Veja também:** [Formulários](forms.md) · [Layout de páginas](page-layout.md)
