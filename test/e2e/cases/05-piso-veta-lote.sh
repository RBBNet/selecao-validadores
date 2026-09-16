#!/usr/bin/env bash
# @desc Três inativos de seis: o piso de 4 operacionais veta o lote inteiro
#
# Objetivo: mostrar que a regra tudo-ou-nada da seleção veta a remoção quando o
# lote de inativos deixaria o conjunto abaixo de 4 operacionais.
# Pré-condições: rede no ar; pilha implantada; modo Automatic.
# O que verifica:
#   - com 3 inativos entre 6, a seleção roda mas nada é removido;
#   - os 3 inativos permanecem operacionais e o conjunto continua em 6.
# Por que não parar containers: com 6 validadores o QBFT exige 4 assinaturas por
# bloco (quorum); parar 3 nós derrubaria a cadeia (caso 07) antes de a seleção
# rodar. Os 3 "inativos" são endereços registrados como operacionais pela
# governança que nunca propõem bloco — a condição medida pelo contrato (nenhum
# bloco proposto na janela) é a mesma, e a rede segue saudável.
# Tempo: ~2,5 min
source "$(dirname "$0")/../lib/e2e.sh"

e2e_case "05 piso mínimo veta o lote"
net_ensure
stack_deploy

ABSENT1=0x00000000000000000000000000000000000000a1
ABSENT2=0x00000000000000000000000000000000000000a2
ABSENT3=0x00000000000000000000000000000000000000a3

log "Montando o conjunto operacional: 3 nós reais + 3 ausentes"
# Remover os 3 ausentes deixaria 3 operacionais, abaixo do mínimo de 4.
# A montagem em si não esbarra nesse piso: na remoção manual, a governança pode
# reduzir o conjunto até 1 operacional; é a seleção automática que exige 4.
for i in 3 4 5; do
  send "$SELECTION" 'removeOperationalValidatorByAddress(address)' "${V[$i]}"
done
for a in "$ABSENT1" "$ABSENT2" "$ABSENT3"; do
  send "$SELECTION" 'addEligibleValidatorByAddress(address,bool)' "$a" true
done
check "conjunto operacional montado com 3 reais + 3 ausentes" \
  "6" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"

log "Modo Automatic"
stack_automatic

log "Ciclo 1 — proteção"
burn_protection_cycle
check "ciclo de proteção: recém-incluídos não são avaliados" \
  "6" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"

log "Ciclo 2 — sem proteção, os 3 ausentes são detectados inativos"
run_cycle "ciclo de avaliação"
check "a seleção rodou neste ciclo" \
  "sim" "$([ "$(events 'SelectionExecuted(address[])' "$CYCLE_START")" -ge 1 ] && echo sim || echo não)"
check "nenhuma remoção aconteceu: o lote de 3 foi vetado pelo piso" \
  "0" "$(events 'OperationalValidatorRemoved(address)' "$CYCLE_START")"
check "os 3 inativos seguem operacionais" "true true true" \
  "$(call "$SELECTION" 'isOperational(address)(bool)' "$ABSENT1") \
$(call "$SELECTION" 'isOperational(address)(bool)' "$ABSENT2") \
$(call "$SELECTION" 'isOperational(address)(bool)' "$ABSENT3")"
check "conjunto operacional segue com 6" \
  "6" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"

e2e_report
