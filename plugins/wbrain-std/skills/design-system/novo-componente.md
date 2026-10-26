# Novo componente

Roteiro para pensar um componente com o usuário. Pergunte só o que o contexto ainda não respondeu.

## 1. Problema antes da forma
- Que tarefa do usuário final ele resolve? Em quais telas aparece?
- Já existe algo parecido no design system? Se sim, é **variante** (nova prop), **composição** (`components/common/` sobre peças existentes) ou de fato peça nova? Prefira, nesta ordem, variante, composição e peça nova.
- Existe padrão consolidado (WAI-ARIA Authoring Practices, Shadcn, Radix)? Partir dele evita reinventar comportamento de teclado e acessibilidade.

## 2. API
- Props: nome, tipo, padrão, obrigatoriedade. Nomes consistentes com os componentes existentes (`variant`, `size`, `disabled`, `onValueChange`...).
- Controlado, não controlado ou ambos (`value`/`defaultValue`/`onValueChange`)?
- Composição por filhos/slots (`<Stepper.Item>`) ou por dados (`items={[...]}`)? Slots dão flexibilidade; dados dão consistência.
- Integração com React Hook Form, quando for campo.

## 3. Estados e casos de borda
Vazio, carregando, erro, disabled, readonly, conteúdo longo (truncar? quebrar?), muitos itens, um item só, valores extremos, sem permissão.

## 4. Acessibilidade e interação
Papel ARIA, rótulo acessível, navegação e atalhos de teclado, gestão de foco (entrada, saída, retorno), anúncio de mudanças (`aria-live`), toque e alvos de clique.

## 5. Responsivo e conteúdo
Comportamento no celular (vira lista? sheet?), textos via `t()`, formatos de data/número pelo locale.

## Decisões antecipadas (componentes complexos)

Antes de desenhar, liste as decisões que mudam a arquitetura do componente e resolva uma por vez, cada uma com opções e a sua recomendação. Exemplos:

- **Tabela editável:** edição inline ou em modal? salva por célula ou por linha? validação síncrona ou no servidor? como desfazer?
- **Calendário/agenda:** visões (dia/semana/mês)? fuso horário de quem? eventos sobrepostos? arrastar para reagendar?
- **Upload:** um ou vários arquivos? limites de tamanho e tipo? progresso e cancelamento? pré-visualização?
- **Wizard:** etapas puláveis? salvamento parcial? voltar perde dados?
- **Filtros combinados:** aplicação imediata ou por botão? filtros na URL? como mostrar filtros ativos e limpar?

Se o componente ainda parecer grande, proponha a menor versão que já entrega valor e deixe o resto como evolução registrada no fechamento.
