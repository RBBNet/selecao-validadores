#!/usr/bin/env bash
#
# Configuração compartilhada, atalhos de RPC e contagem de falhas.
# Carregado por lib/e2e.sh — não executar direto.

set -uo pipefail

E2E_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${E2E_LIB_DIR}/../../.." && pwd)"
cd "$REPO_ROOT" || exit 1

COMPOSE_DIR="test/e2e/docker/besu"
RPC="${E2E_RPC:-http://localhost:8545}"

# Conta pré-financiada no genesis: governança e deployer.
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
DEPLOYER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export E2E_ORG2_ADMIN=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720

# O QBFT roda round-robin entre os 6 validadores, então cada um propõe a cada 6
# blocos. O threshold precisa de folga sobre esse período (senão um round change
# derruba um validador saudável) e blocksBetweenSelection precisa ser maior que
# o threshold, senão nenhuma remoção jamais acontece.
export E2E_BLOCKS_BETWEEN_SELECTION="${E2E_BLOCKS_BETWEEN_SELECTION:-30}"
export E2E_BLOCKS_WITHOUT_PROPOSE_THRESHOLD="${E2E_BLOCKS_WITHOUT_PROPOSE_THRESHOLD:-18}"
export E2E_SELECTION_OFFSET="${E2E_SELECTION_OFFSET:-30}"

# Gás explícito: eth_estimateGas para executeMonitoring roda contra um estado em
# que a função retorna cedo (bloco já monitorado) e subestima o custo do bloco em
# que a transação de fato executa, fazendo a chamada reverter por falta de gás.
GAS_LIMIT=5000000

FAILURES=0

log()  { printf '\n\033[1m-- %s\033[0m\n' "$*"; }
call() { cast call "$@" --rpc-url "$RPC" 2>/dev/null; }
send() { cast send "$@" --private-key "$PRIVATE_KEY" --rpc-url "$RPC" --legacy --gas-limit "$GAS_LIMIT" >/dev/null 2>&1; }

# Todo número que entre em aritmética ou em comparação numérica precisa passar
# por aqui: a partir de 10000 o cast anexa a notação científica ao valor
# ("12345 [1.234e4]"), e o bash quebra com "esperava expressão de número
# inteiro". Como a rede é reaproveitada entre execuções, a altura da cadeia
# cruza 10000 depois de algumas horas no ar e o e2e passaria a falhar sozinho.
num()  { awk '{print $1}'; }
call_uint() { call "$@" | num; }
blk()  { cast block-number --rpc-url "$RPC" 2>/dev/null | num || echo 0; }

check() {
  if [ "$2" = "$3" ]; then
    printf '  \033[32mOK\033[0m   %s\n       esperado = obtido = %s\n' "$1" "$2"
  else
    printf '  \033[31mFALHA\033[0m %s\n       esperado: %s\n       obtido:   %s\n' "$1" "$2" "$3"
    FAILURES=$((FAILURES + 1))
  fi
}

count() { echo "$1" | tr ',' '\n' | grep -c '0x'; }
lower() { echo "$1" | tr 'A-F' 'a-f'; }

# "sim" se a chamada reverte com o erro customizado esperado — para usar direto
# em check(). Uso: reverts_with 'SameAddress(address)' "$ALVO" 'f(address)' "$arg"
#
# Simula com cast call em vez de cast send: com --gas-limit explícito o send não
# falha localmente, a transação entra na cadeia e só então reverte, sem devolver
# sinal utilizável ao script.
#
# Casa pelo seletor do erro, não pelo status de saída. Um cast que reverte também
# sai com erro quando a assinatura da função não existe (o contrato reverte no
# fallback), então confiar no status de saída faria um erro de digitação passar
# como se a validação estivesse funcionando. A distinção: o fallback devolve data
# vazia, o erro customizado devolve o seletor esperado.
reverts_with() { reverts_with_from "$DEPLOYER" "$@"; }

# Igual, mas simulando a partir de outro remetente — necessário para os caminhos
# que só rodam quando quem chama NÃO é a governança.
reverts_with_from() {
  local from="$1" expected="$2"; shift 2
  local want data
  want=$(cast sig "$expected" 2>/dev/null)
  data=$(cast call "$@" --from "$from" --rpc-url "$RPC" 2>&1 | grep -oP 'data: "\K0x[0-9a-fA-F]*')
  if [ "${data:0:10}" = "$want" ]; then
    echo "sim"
  else
    echo "não (data=${data:-ausente}, esperado ${want})"
  fi
}

# Envia assinando com outra conta que não a governança.
#
# --gas-price 0 porque as contas de organização não são financiadas no genesis;
# a rede roda com zeroBaseFee e --min-gas-price=0, então saldo zero basta.
send_as() {
  local key="$1"; shift
  cast send "$@" --private-key "$key" --rpc-url "$RPC" --legacy \
    --gas-price 0 --gas-limit "$GAS_LIMIT" >/dev/null 2>&1
}

# Lê a chave pública de um nó real do compose e devolve "enodeHigh enodeLow".
# O arquivo tem 0x + 128 hex (64 bytes), que o contrato trata como dois bytes32.
enode_of() {
  local pub
  pub=$(tr -d '\n' < "${COMPOSE_DIR}/nodes/$1/key.pub")
  pub=${pub#0x}
  echo "0x${pub:0:64} 0x${pub:64:64}"
}

# Reimplementa em bash a derivação que o contrato faz em _calculateAddress:
# últimos 20 bytes de keccak256(enodeHigh || enodeLow). Serve para saber em que
# endereço cravar a asserção — e, sendo implementação independente, também
# funciona como conferência cruzada da derivação do contrato.
addr_of_enode() {
  local h="${1#0x}" l="${2#0x}"
  cast keccak "0x${h}${l}" | sed 's/^0x.\{24\}/0x/'
}

# Cabeçalho do caso. Guarda o instante inicial para o relatório final.
E2E_CASE_NAME=""
E2E_CASE_START=0
e2e_case() {
  E2E_CASE_NAME="$1"
  E2E_CASE_START=$(date +%s)
  printf '\n\033[1;36m=== %s ===\033[0m\n' "$1"
}

# Encerra o caso com o número de falhas como código de saída, que é o que o
# orquestrador soma.
e2e_report() {
  local secs=$(( $(date +%s) - E2E_CASE_START ))
  if [ "$FAILURES" -eq 0 ]; then
    printf '\n\033[32m== %s: todas as verificações passaram (%ss) ==\033[0m\n' "$E2E_CASE_NAME" "$secs"
  else
    printf '\n\033[31m== %s: %d verificação(ões) falharam (%ss) ==\033[0m\n' "$E2E_CASE_NAME" "$FAILURES" "$secs"
  fi
  exit "$FAILURES"
}
