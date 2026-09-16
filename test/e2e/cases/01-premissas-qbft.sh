#!/usr/bin/env bash
# @desc Premissas do QBFT: coinbase é o proposer e o round-robin gira (sem contratos)
#
# Objetivo: confirmar as premissas do consenso QBFT das quais o monitoramento
# automático depende e que os testes unitários apenas assumem.
# Pré-condições: rede Besu QBFT de 6 nós no ar; nenhum contrato é implantado.
# O que verifica:
#   - block.coinbase é o endereço do validador que propôs o bloco;
#   - os 6 validadores se alternam na produção de blocos (round-robin);
#   - todo proposer observado pertence ao conjunto de validadores do QBFT.
# Tempo: ~10 s
source "$(dirname "$0")/../lib/e2e.sh"

e2e_case "01 premissas do QBFT"
net_ensure

log "block.coinbase é mesmo o proposer?"
_wait_height 7 60 || { echo "  FALHA: cadeia não chegou ao bloco 7"; exit 1; }

MINERS=""
for b in 1 2 3 4 5 6; do
  MINERS="${MINERS} $(lower "$(cast block "$b" --rpc-url "$RPC" 2>/dev/null | grep -i '^miner' | awk '{print $2}')")"
done
DISTINCT=$(echo "$MINERS" | tr ' ' '\n' | grep -c '0x')
UNIQUE=$(echo "$MINERS" | tr ' ' '\n' | grep '0x' | sort -u | wc -l)
check "os 6 primeiros blocos têm 6 proposers distintos (round-robin)" "6 6" "$DISTINCT $UNIQUE"

QBFT_SET=$(lower "$(cast rpc qbft_getValidatorsByBlockNumber '"latest"' --rpc-url "$RPC" 2>/dev/null | tr -d '[]" ')")
FOREIGN=0
for m in $MINERS; do
  case ",${QBFT_SET}," in
    *",${m},"*) ;;
    *) FOREIGN=$((FOREIGN + 1)) ;;
  esac
done
check "todo proposer observado pertence ao conjunto de validadores QBFT" "0" "$FOREIGN"

e2e_report
