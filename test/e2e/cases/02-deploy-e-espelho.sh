#!/usr/bin/env bash
# @desc Deploy da pilha real: governança, contratos externos e Ingress espelhando a lógica
#
# Objetivo: implantar a pilha completa (permissionamento real + ValidatorSelection
# + Ingress) e comprovar que ela sobe ligada aos contratos reais, sem dublês.
# Pré-condições: rede no ar; conta de governança financiada no genesis.
# O que verifica:
#   - o contrato referencia AdminProxy, AccountRulesV2Impl e NodeRulesV2Impl reais;
#   - o conjunto operacional inicial é o dos 6 validadores ativos no QBFT;
#   - o Ingress espelha exatamente o conjunto da lógica;
#   - o contrato inicia em modo Manual, com o conjunto operacional protegido.
# Tempo: ~10 s
source "$(dirname "$0")/../lib/e2e.sh"

e2e_case "02 deploy e espelho do Ingress"
net_ensure
stack_deploy

log "Referências externas apontam para os contratos reais"
check "governança é o Admin real" "true" "$(call "$ADMIN" 'isAuthorized(address)(bool)' "$DEPLOYER")"
check "accountsContract é o AccountRulesV2Impl real" \
  "$(lower "$ACCOUNTS")" "$(lower "$(call "$SELECTION" 'accountsContract()(address)')")"
check "nodesContract é o NodeRulesV2Impl real" \
  "$(lower "$NODES")" "$(lower "$(call "$SELECTION" 'nodesContract()(address)')")"

log "Conjunto inicial == validadores reais do QBFT"
OPER=$(call "$SELECTION" 'getValidators()(address[])')
check "os 6 validadores do Besu estão operacionais no contrato" "6" "$(count "$OPER")"
check "Ingress espelha a lógica" "$OPER" "$(call "$INGRESS" 'getValidators()(address[])')"

log "Estado inicial do ciclo"
check "contrato inicia em modo Manual" "0" "$(call "$SELECTION" 'operationMode()(uint8)')"
check "todo o conjunto inicial nasce protegido" \
  "6" "$(count "$(call "$SELECTION" 'getProtectedValidators()(address[])')")"

e2e_report
