# Formulários — React Hook Form + Zod

[← Frontend](frontend.md)

Todo formulário usa `React Hook Form` com validação via `Zod`. A integração com Shadcn/UI é feita pelo componente `<Form>` do próprio Shadcn, exportado por `@design-system/ui`.

O login é **sem senha**, por OTP em dois passos (ver [fluxo de autenticação](../auth/flow.md)): primeiro o
usuário informa o e-mail (`authService.requestOtp`); depois informa o **código** recebido
(`authService.verifyOtp`). O exemplo abaixo é o passo de verificação — e-mail + código,
ambos validados pelo Zod.

```typescript
// src/components/features/auth/LoginForm.tsx

import { useMemo } from "react"
import { useForm } from "react-hook-form"
import { useTranslation } from "react-i18next"
import type { TFunction } from "i18next"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import {
  Button, Form, FormControl, FormField, FormFooter, FormItem, FormLabel, FormMessage, Input,
} from "@design-system/ui"
import { requiredEmail } from "@/lib/schemas/common"

// fábrica: as mensagens de validação vêm do i18n
const createLoginSchema = (t: TFunction) =>
  z.object({
    email: requiredEmail(t("auth.errors.email_required"), t("auth.errors.email_invalid")),
    code: z.string().regex(/^\d{6}$/, t("auth.errors.code_format")),
  })

type LoginFormData = z.infer<ReturnType<typeof createLoginSchema>>

export function LoginForm({ onSubmit }: { onSubmit: (data: LoginFormData) => Promise<void> }) {
  const { t } = useTranslation()
  const schema = useMemo(() => createLoginSchema(t), [t])
  const form = useForm<LoginFormData>({
    resolver: zodResolver(schema),
    defaultValues: { email: "", code: "" },
  })

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>{t("auth.fields.email")}</FormLabel>
              <FormControl>
                <Input type="email" {...field} />
              </FormControl>
              <FormMessage />  {/* exibe erros do Zod automaticamente */}
            </FormItem>
          )}
        />
        <FormField
          control={form.control}
          name="code"
          render={({ field }) => (
            <FormItem>
              <FormLabel>{t("auth.fields.code")}</FormLabel>
              <FormControl>
                <Input inputMode="numeric" autoComplete="one-time-code" maxLength={6} {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <FormFooter>
          <Button type="submit" disabled={form.formState.isSubmitting}>
            {form.formState.isSubmitting ? t("auth.actions.signing_in") : t("auth.actions.sign_in")}
          </Button>
        </FormFooter>
      </form>
    </Form>
  )
}
```

**Regras:**
- Schemas Zod definidos junto ao formulário ou em `src/lib/schemas/` quando reutilizados entre páginas.
- Schemas com mensagens são **fábricas que recebem `t`** (`createXSchema(t)`), memorizadas com `useMemo` no componente — nunca mensagem hardcoded.
- Reaproveite os validadores comuns de `lib/schemas/common.ts` (`requiredString`, `requiredEmail`) em vez de repetir `z.string().min(1, ...)`/`.email(...)`.
- Campos que vão para a API usam os nomes do contrato, em **snake_case** (ex.: `is_active`) — o valor do formulário é enviado sem conversão (ver [Comunicação com a API](api-client.md)).
- Nunca use `any` — derive os tipos do schema com `z.infer`.
- Ações ficam no `FormFooter`, com botões em tamanho natural (ver [Layout e componentes de página](page-layout.md#rodapé-de-formulário--formfooter)).
- Erros de API (ex: código inválido ou expirado) devem ser mapeados com `form.setError("field", { message })`.

---

**Veja também:** [Estrutura e qualidade de formulários](form-design.md) · [Validadores Zod compartilhados](shared-utilities.md#validadores-zod-compartilhados--libschemascommonts)
