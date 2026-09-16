#!/usr/bin/env bash
# @desc Mesmos três inativos, agora com folga sobre o piso: o lote sai inteiro numa seleção
#
# Objetivo: contraponto do caso 05 — quando o piso de 4 operacionais não é
# violado, o lote inteiro de inativos é removido de uma só vez.
# Pré-condições: rede no ar; pilha implantada; modo Automatic.
# O que verifica:
#   - os 3 inativos são removidos e as 3 remoções caem no mesmo bloco de seleção;
#   - os 6 nós reais permanecem e os removidos continuam elegíveis;
#   - o Ingress reflete o novo conjunto.
# Tempo: ~2,5 min
source "$(dirname "$0")/../lib/e2e.sh"

e2e_case "06 lote removido com folga sobre o piso"
net_ensure
stack_deploy

ABSENT1=0x00000000000000000000000000000000000000a1
ABSENT2=0x00000000000000000000000000000000000000a2
ABSENT3=0x00000000000000000000000000000000000000a3

log "Montando o conjunto operacional: 6 nós reais + 3 ausentes"
for a in "$ABSENT1" "$ABSENT2" "$ABSENT3"; do
  send "$SELECTION" 'addEligibleValidatorByAddress(address,bool)' "$a" true
done
check "conjunto operacional com 9 (6 reais + 3 ausentes)" \
  "9" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"

log "Modo Automatic"
stack_automatic

log "Ciclo 1 — proteção"
burn_protection_cycle

log "Ciclo 2 — sem proteção, o lote de 3 é autorizado"
run_cycle "ciclo de avaliação"
check "os 3 inativos foram removidos" \
  "3" "$(events 'OperationalValidatorRemoved(address)' "$CYCLE_START")"
check "as 3 remoções saíram no mesmo bloco de seleção" \
  "1" "$(event_blocks 'OperationalValidatorRemoved(address)' "$CYCLE_START")"
check "restam os 6 nós reais" \
  "6" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"
check "os removidos continuam elegíveis" "true true true" \
  "$(call "$SELECTION" 'isEligible(address)(bool)' "$ABSENT1") \
$(call "$SELECTION" 'isEligible(address)(bool)' "$ABSENT2") \
$(call "$SELECTION" 'isEligible(address)(bool)' "$ABSENT3")"
check "Ingress reflete o novo conjunto" \
  "$(call "$SELECTION" 'getValidators()(address[])')" "$(call "$INGRESS" 'getValidators()(address[])')"

e2e_report
