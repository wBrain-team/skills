# Subagentes e contexto

Regras comuns às skills wbrain-std que usam subagentes.

- O agente principal **orquestra**; subagentes fazem o trabalho pesado de leitura e exploração para poupar contexto e custo.
- Cada subagente recebe uma tarefa **pequena, objetiva e autocontida**, com todo o contexto necessário no prompt (ele não vê a conversa).
- Todo prompt de subagente exige um **retorno enxuto em formato fixo**: bullets, até ~30 linhas, sem colar código. Use caminhos de arquivo em vez de trechos.
- Ao apontar um trecho específico, o subagente usa `caminho:linha` ou `caminho:início-fim` (ex.: `backend/app/services/user.py:42-67`). Assim o principal lê só aquele intervalo (Read com `offset`/`limit`) e não o arquivo inteiro. Se a referência é ao arquivo todo, basta o caminho; não procure linhas só para cumprir o formato.
- Dispare em paralelo (uma única mensagem) os subagentes que não dependem uns dos outros.
