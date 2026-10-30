#!/usr/bin/env bash
# Funções comuns aos casos de eval.

# Cria em $1 um mini projeto STD na branch base ($BASE_BRANCH, padrão main), com snaps por domínio,
# código e teste, e grava .std/config.json (exceto com NO_CONFIG=1). Um caso pode definir
# BASE_BRANCH/NO_CONFIG num env.sh na sua pasta (lido pelo run.sh antes do base_repo).
base_repo() {
  local d=$1
  mkdir -p "$d" && cd "$d" || return 1
  git init -q -b "${BASE_BRANCH:-main}"
  git config user.email eval@wbrain.local
  git config user.name eval
  mkdir -p snaps/base snaps/pedidos docs app tests
  printf '.std/\n' > .gitignore
  cat > AGENTS.md <<'EOF'
# AGENTS.md
Projeto de exemplo do fluxo wbrain-std. `snaps/` é a fonte da verdade; `docs/` guarda as guidelines.
Testes: `python -m pytest tests/<arquivo>` (pontual) e `python -m pytest` (suíte).
EOF
  cat > docs/docs.md <<'EOF'
# Docs
Projeto pequeno em Python, sem banco. Camada única: `app/`. Testes em `tests/`, com marcador `# snap:`.
EOF
  cat > snaps/snaps.md <<'EOF'
# Snaps

Organização: por domínio de negócio; dentro de cada domínio, por telas.

## Domínios
- [Regras de pedidos](pedidos/regras.md)
- [Lista de pedidos](pedidos/lista.md)
- [Histórico de pedidos](pedidos/historico.md)

## Transversais
- [Lista base](base/data-list.md)

## Glossário
- **Cliente**: quem faz pedidos.
EOF
  cat > snaps/base/data-list.md <<'EOF'
# Lista base

## Comportamento
- A lista mostra 20 itens por página, do mais recente ao mais antigo.
- Sem itens: mostra "Nada por aqui".
EOF
  cat > snaps/pedidos/regras.md <<'EOF'
# Regras de pedidos

## Comportamento
- O frete custa R$ 15,00.
- Só o administrador cancela pedidos.
EOF
  cat > snaps/pedidos/lista.md <<'EOF'
Extends: [Lista base](../base/data-list.md)

# Lista de pedidos

## Comportamento
- O cliente vê só os próprios pedidos.
EOF
  cat > snaps/pedidos/historico.md <<'EOF'
Extends: [Lista base](../base/data-list.md)

# Histórico de pedidos

## Comportamento
- O cliente vê os pedidos entregues.
EOF
  cat > app/pedidos.py <<'EOF'
PAGE_SIZE = 20
FRETE = 15.00


def pode_cancelar(papel):
    return papel == "admin"
EOF
  cat > tests/test_pedidos.py <<'EOF'
# snap: snaps/pedidos/regras.md
from app.pedidos import FRETE, pode_cancelar


def test_frete():
    assert FRETE == 15.00


def test_so_admin_cancela():
    assert pode_cancelar("admin") and not pode_cancelar("cliente")
EOF
  touch app/__init__.py
  [ "${NO_CONFIG:-0}" = 1 ] || write_config "${BASE_BRANCH:-main}"
  git add -A && git commit -qm "base"
}

# Grava .std/config.json (ignorado pelo git) com a branch base.
write_config() {
  mkdir -p .std
  printf '{ "schema_version": 1, "base_branch": "%s" }\n' "$1" > .std/config.json
}
# Branch base configurada do caso.
base_branch() { sed -n 's/.*"base_branch"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .std/config.json; }

# Cria a branch de trabalho do caso.
work_branch() { git checkout -qb "feat/${1:-eval}"; }

# --- asserções (rodam dentro do repo do caso) ---
fail() { echo "FALHOU: $*"; exit 1; }
state_file() { ls .std/${STATE_SKILL:-tuning}/*.md 2>/dev/null | head -1; }
assert_state() {  # assert_state <regex>
  local f; f=$(state_file); [ -n "$f" ] || fail "sem arquivo de estado"
  grep -qiE "$1" "$f" || fail "estado não casa /$1/"
}
assert_no_state() { [ -z "$(state_file)" ] || fail "arquivo de estado criado"; }
assert_snaps_untouched() {
  git diff --quiet HEAD -- snaps/ && [ -z "$(git ls-files --others --exclude-standard snaps/)" ] \
    || fail "snaps/ foi alterado"
}
assert_code_untouched() {
  git diff --quiet HEAD -- app tests || fail "código alterado antes da aprovação"
}
assert_output() {  # assert_output <arquivo-de-saída> <regex>
  grep -qiE "$2" "$1" || fail "saída não casa /$2/"
}
