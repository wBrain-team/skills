# Variáveis de ambiente (`VITE_*`)

[← Frontend](frontend.md)

O Vite só expõe ao cliente variáveis com prefixo `VITE_`, acessadas via
`import.meta.env`.

```ts
const baseURL = import.meta.env.VITE_API_URL // usado na instância do axios
```

**Regras:**
- Cada app tem seu `.env` (e um `.env.example` versionado, sem valores reais).
- **Nunca** coloque segredo de servidor numa `VITE_*` — tudo que tem esse prefixo é
  embarcado no bundle e fica **público**.
- Tipos opcionais em `vite-env.d.ts` (`interface ImportMetaEnv`) para autocomplete.

---

**Veja também:** [Segurança](../guidelines/security.md)
