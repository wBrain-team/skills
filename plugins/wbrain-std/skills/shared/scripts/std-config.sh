#!/usr/bin/env bash
# Lê o .std/config.json do projeto (criado pela skill wbrain-std:config).
# Uso: std-config.sh get <chave>   imprime o valor da chave (ex.: base_branch)
#      std-config.sh base-ref      imprime a ref da branch base (local ou origin/)
#      std-config.sh protected     lista as branches protegidas (base + main + master)
# Saída: 0 = ok | 1 = erro | 2 = config ausente ou inválido (rodar /wbrain-std:config)
set -uo pipefail

top=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "ERRO: não é um repositório git." >&2; exit 1; }
cfg="$top/.std/config.json"

need_config() {
  echo "CONFIG AUSENTE: $cfg não existe ou está inválido. Rode /wbrain-std:config para configurar a branch base." >&2
  exit 2
}

# Valor de uma chave string do JSON (sem exigir jq).
json_get() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -er --arg k "$key" '.[$k] | select(type == "string" and length > 0)' "$cfg" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    python3 -I - "$cfg" "$key" <<'PY' 2>/dev/null
import json, sys
v = json.load(open(sys.argv[1])).get(sys.argv[2])
if not isinstance(v, str) or not v:
    sys.exit(1)
print(v)
PY
  else
    sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]\{1,\}\)\".*/\1/p" "$cfg" | head -n 1 | grep .
  fi
}

get() {
  [ -f "$cfg" ] || need_config
  json_get "$1" || need_config
}

case "${1:-}" in
  get)
    [ -n "${2:-}" ] || { echo "ERRO: informe a chave." >&2; exit 1; }
    get "$2" ;;
  base-ref)
    base=$(get base_branch) || exit $?
    for ref in "$base" "origin/$base"; do
      if git rev-parse --verify -q "$ref^{commit}" >/dev/null; then echo "$ref"; exit 0; fi
    done
    echo "ERRO: branch base '$base' não encontrada (nem local, nem origin/$base). Rode /wbrain-std:config para corrigir." >&2
    exit 1 ;;
  protected)
    base=$(get base_branch) || exit $?
    printf '%s\n' "$base" main master | awk '!seen[$0]++' ;;
  *)
    echo "Uso: std-config.sh get <chave> | base-ref | protected" >&2; exit 1 ;;
esac
