#!/usr/bin/env bash
# @desc Nó real derrubado sai do conjunto operacional na seleção e a governança o reinclui depois
#
# Objetivo: mostrar que um validador que deixa de produzir blocos é removido do
# conjunto operacional pela seleção automática e pode ser reincluído pela governança.
# Pré-condições: rede no ar; pilha implantada; modo Automatic; ciclo de proteção queimado.
# O que verifica:
#   - o nó cujo container foi parado sai do operacional e permanece elegível;
#   - restam 5 operacionais e o Ingress reflete o novo conjunto;
#   - reincluído pela governança, o nó volta operacional e entra protegido.
# Observação: a rede está em modo cabeçalho de bloco — o que se mede é a lista do
# contrato. A saída do nó do consenso real é coberta pelo caso 11, após a transição.
# Tempo: ~2,5 min
source "$(dirname "$0")/../lib/e2e.sh"

e2e_case "04 nó inativo é removido e reincluído"
net_ensure
stack_deploy

log "Modo Automatic"
stack_automatic

log "Ciclo 1 — proteção (nada é avaliado enquanto o conjunto está protegido)"
burn_protection_cycle

log "Ciclo 2 — com um nó real parado"
DEAD="${V[5]}"
echo "  parando besu-node5 (${DEAD})"
node_stop besu-node5
run_cycle "ciclo com nó parado"

check "o nó parado saiu do conjunto operacional" \
  "false" "$(call "$SELECTION" 'isOperational(address)(bool)' "$DEAD")"
check "o nó parado continua elegível" \
  "true" "$(call "$SELECTION" 'isEligible(address)(bool)' "$DEAD")"
check "restam 5 operacionais" \
  "5" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"
check "Ingress reflete o novo conjunto" \
  "$(call "$SELECTION" 'getValidators()(address[])')" "$(call "$INGRESS" 'getValidators()(address[])')"

log "Reinclusão pela governança depois que o nó volta"
node_start besu-node5
send "$SELECTION" 'addOperationalValidatorByAddress(address)' "$DEAD"
check "nó reincluído no conjunto operacional" \
  "true" "$(call "$SELECTION" 'isOperational(address)(bool)' "$DEAD")"
check "quem é reincluído entra protegido, sem ser avaliado no ciclo em curso" \
  "true" "$(call "$SELECTION" 'isProtected(address)(bool)' "$DEAD")"
check "conjunto operacional de volta a 6" \
  "6" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"

e2e_report
