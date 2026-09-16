#!/usr/bin/env bash
#
# Orquestrador dos testes ponta a ponta contra uma rede Besu QBFT real em Docker,
# sem dublês: 6 nós validadores, pilha de permissionamento real e os contratos do
# projeto.
#
# Os proposers são os reais do round-robin do QBFT, os blocos avançam sozinhos
# (blockperiodseconds) e a inatividade de um validador é provocada parando o
# container do nó — nenhuma dessas condições é forjada.
#
# Cada caso em cases/ é independente: implanta a própria pilha de contratos e
# monta a própria pré-condição. A rede Besu, que é a parte cara, é compartilhada.
# Por isso dá para rodar só o caso que interessa depois de mexer no contrato, sem
# esperar a suíte inteira.
#
#   test/e2e/run-e2e-besu.sh                 # suíte completa, rede recriada do zero
#   test/e2e/run-e2e-besu.sh 04              # só o caso 04, na rede que já estiver no ar
#   test/e2e/run-e2e-besu.sh 05 06           # dois casos, na ordem dada
#   test/e2e/run-e2e-besu.sh --fresh 04      # recria a rede antes de rodar o 04
#   test/e2e/run-e2e-besu.sh --list          # lista os casos disponíveis
#   test/e2e/run-e2e-besu.sh --down          # derruba a rede ao final
#
# Um caso também roda direto, sem o orquestrador:
#   test/e2e/cases/04-no-inativo-removido.sh
#
set -uo pipefail

cd "$(dirname "$0")/../.." || exit 1
CASES_DIR="test/e2e/cases"

FRESH=""
DOWN=0
SELECTORS=()

usage() {
  # Imprime o cabeçalho até a primeira linha que não é comentário. Uma faixa
  # fixa de linhas desanda assim que o banner muda de tamanho, e o `--help`
  # passa a cuspir `set -uo pipefail` como se fosse documentação.
  sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^#\{1,2\} \{0,1\}//'
  exit 0
}

list_cases() {
  printf '\033[1mCasos disponíveis\033[0m\n'
  for f in "$CASES_DIR"/*.sh; do
    printf '  \033[36m%-32s\033[0m %s\n' \
      "$(basename "$f" .sh)" "$(grep -m1 '^# @desc ' "$f" | cut -c9-)"
  done
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)  usage ;;
    -l|--list)  list_cases ;;
    --fresh)    FRESH=1 ;;
    --reuse)    FRESH=0 ;;
    --down)     DOWN=1 ;;
    -*)         echo "opção desconhecida: $1"; exit 2 ;;
    *)          SELECTORS+=("$1") ;;
  esac
  shift
done

# Resolve um seletor ("04", "inativo", "04-no-inativo-removido") em um arquivo.
resolve_case() {
  local sel="$1" hits
  hits=$(ls "$CASES_DIR/${sel}"*.sh 2>/dev/null)
  [ -z "$hits" ] && hits=$(ls "$CASES_DIR"/*"${sel}"*.sh 2>/dev/null)
  if [ -z "$hits" ]; then
    echo "nenhum caso corresponde a '${sel}'. Use --list." >&2
    return 1
  fi
  if [ "$(echo "$hits" | wc -l)" -gt 1 ]; then
    echo "'${sel}' é ambíguo:" >&2; echo "$hits" >&2
    return 1
  fi
  echo "$hits"
}

TO_RUN=()
if [ ${#SELECTORS[@]} -eq 0 ]; then
  # Suíte completa: a rede é recriada do zero por padrão, para a corrida não
  # herdar o estado de uma execução anterior.
  for f in "$CASES_DIR"/*.sh; do TO_RUN+=("$f"); done
  FRESH="${FRESH:-1}"
else
  # Subconjunto: reaproveita a rede no ar por padrão, que é o modo rápido de
  # reverificar um cenário depois de mexer no contrato.
  for sel in "${SELECTORS[@]}"; do
    f=$(resolve_case "$sel") || exit 2
    TO_RUN+=("$f")
  done
  FRESH="${FRESH:-0}"
fi

printf '\033[1m== e2e Besu: %d caso(s) ==\033[0m\n' "${#TO_RUN[@]}"
[ "$FRESH" = "1" ] && echo "rede será recriada do zero antes do primeiro caso"

TOTAL_FAILURES=0
BROKEN=0
NAMES=(); RESULTS=(); TIMES=()

for f in "${TO_RUN[@]}"; do
  start=$(date +%s)
  # Só o primeiro caso recria a rede; os seguintes a reaproveitam, senão a suíte
  # gastaria minutos derrubando e subindo Besu entre cenários.
  E2E_FRESH_NET="$FRESH" bash "$f"
  rc=$?
  FRESH=0
  NAMES+=("$(basename "$f" .sh)")
  TIMES+=("$(( $(date +%s) - start ))")
  if [ "$rc" -eq 0 ]; then
    RESULTS+=("OK")
  else
    RESULTS+=("${rc} falha(s)")
    TOTAL_FAILURES=$((TOTAL_FAILURES + rc))
    BROKEN=$((BROKEN + 1))
  fi
done

printf '\n\033[1m== Resumo ==\033[0m\n'
for i in "${!NAMES[@]}"; do
  if [ "${RESULTS[$i]}" = "OK" ]; then
    printf '  \033[32m%-12s\033[0m %-32s %ss\n' "OK" "${NAMES[$i]}" "${TIMES[$i]}"
  else
    printf '  \033[31m%-12s\033[0m %-32s %ss\n' "${RESULTS[$i]}" "${NAMES[$i]}" "${TIMES[$i]}"
  fi
done

if [ "$DOWN" -eq 1 ]; then
  echo "derrubando a rede"
  (cd test/e2e/docker/besu && docker compose down -v >/dev/null 2>&1)
else
  echo "Rede segue no ar. Para derrubar: (cd test/e2e/docker/besu && docker compose down -v)"
fi

if [ "$TOTAL_FAILURES" -eq 0 ]; then
  printf '\033[32m== TODAS AS VERIFICAÇÕES PASSARAM ==\033[0m\n'
else
  printf '\033[31m== %d verificação(ões) falharam em %d caso(s) ==\033[0m\n' "$TOTAL_FAILURES" "$BROKEN"
fi
exit "$TOTAL_FAILURES"
