#!/usr/bin/env bash
# @desc Derrubar 3 dos 6 nós quebra o quorum do QBFT e a cadeia para (justifica o piso do caso 05)
#
# Objetivo: demonstrar por que o piso de 4 operacionais é necessário — sem ele, a
# seleção poderia levar a rede a um estado sem quorum.
# Pré-condições: rede no ar; pilha implantada; modo Automatic.
# O que verifica:
#   - com 3 dos 6 nós parados, a cadeia para de produzir blocos (quorum quebrado);
#   - sem blocos não há monitoração: o conjunto operacional permanece intacto;
#   - religados os 3 nós, a cadeia volta a produzir (condição de saída).
# Observação: este caso para 3 containers e NUNCA deve rodar em paralelo. Como
# deixa a cadeia parada no meio, o religamento é condição de saída: se o quorum
# não voltar, o caso aborta em vez de entregar uma rede morta ao caso seguinte.
# Tempo: ~2 min
source "$(dirname "$0")/../lib/e2e.sh"

e2e_case "07 quebra de quorum do QBFT"
net_ensure
stack_deploy

log "Modo Automatic"
stack_automatic

log "Parando besu-node3, besu-node4 e besu-node5"
node_stop besu-node3 besu-node4 besu-node5
HEIGHT_BEFORE=$(blk)
sleep 30
HEIGHT_AFTER=$(blk)
echo "  altura: ${HEIGHT_BEFORE} -> ${HEIGHT_AFTER} em 30s (com quorum seriam ~15 blocos)"
check "a cadeia parou de produzir blocos" \
  "sim" "$([ "$HEIGHT_AFTER" -le $((HEIGHT_BEFORE + 1)) ] && echo sim || echo não)"
check "sem blocos não há seleção: conjunto operacional intacto" \
  "6" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"

log "Religando os 3 nós"
node_start besu-node3 besu-node4 besu-node5
if _wait_height $((HEIGHT_AFTER + 1)) 45; then
  check "a cadeia volta a produzir assim que o quorum é restabelecido" "sim" "sim"
else
  check "a cadeia volta a produzir assim que o quorum é restabelecido" "sim" "não"
  echo "  a rede não se recuperou em 90s; abortando para não entregar cadeia parada ao próximo caso"
  e2e_report
fi

e2e_report
