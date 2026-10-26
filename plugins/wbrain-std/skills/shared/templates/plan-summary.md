## Plano — <branch>

Entendimento do snapshot
- snapshots/<arquivo>.md: <regra, em uma linha>

Mudança no snapshot → como será garantida
- "<trecho do snapshot>" → teste: <cenário(s)>

A confirmar (leitura adotada com alternativa de comportamento diferente; "nenhuma" se não houver)
- snapshots/<arquivo>.md:<linha> — "<trecho>" → li como: <leitura adotada> (<evidência>); alternativa descartada: <...>

Premissas toleráveis (imprecisões deduzidas do contexto; "nenhuma" se não houver)
- snapshots/<arquivo>.md:<linha> — "<trecho>" → <leitura adotada>

Tarefas (<n>): <x> paralelas, <y> sequenciais
Camadas: <camadas>
Atenção: <migrations, remoções, contratos de API alterados, ou "nada">
Docs: <docs a criar/atualizar/remover; ADR novo: sim/não>

Seguir com a implementação?

---

## Variante curta (trilha curta)

## Plano (trilha curta) — <branch>
- Muda: snapshots/<arquivo>.md — <regra, em uma linha>
- Garantia: teste <cenário> (`<comando pontual>`)
- Tarefas: <1 a 3, em uma linha cada>
- Premissas: <a confirmar em destaque, toleráveis em uma linha, ou "nenhuma">

Seguir com a implementação?
