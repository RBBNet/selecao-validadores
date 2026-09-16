#!/usr/bin/env bash
#
# Ponto de entrada das bibliotecas do e2e. Todo caso começa com:
#
#   source "$(dirname "$0")/../lib/e2e.sh"
#
# Variáveis de ambiente reconhecidas:
#   E2E_RPC        endpoint JSON-RPC (padrão http://localhost:8545)
#   E2E_FRESH_NET  1 recria a rede Besu do zero antes de rodar
#   E2E_BLOCKS_BETWEEN_SELECTION / _WITHOUT_PROPOSE_THRESHOLD / E2E_SELECTION_OFFSET

_E2E_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${_E2E_LIB}/common.sh"
# shellcheck source=net.sh
. "${_E2E_LIB}/net.sh"
# shellcheck source=stack.sh
. "${_E2E_LIB}/stack.sh"
# shellcheck source=cycle.sh
. "${_E2E_LIB}/cycle.sh"
# shellcheck source=consensus.sh
. "${_E2E_LIB}/consensus.sh"
