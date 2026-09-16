#!/usr/bin/env bash
# @desc Modo Automatic e ciclo com a rede saudável: cobertura do monitoramento e ninguém sai
#
# Objetivo: em modo Automatic com os 6 nós saudáveis, mostrar que o monitoramento
# cobre a janela entre seleções e que nenhum validador é removido.
# Pré-condições: rede no ar; pilha implantada; conjunto operacional de 6.
# O que verifica:
#   - a proteção é limpa ao fim do primeiro ciclo (que apenas queima a proteção);
#   - no segundo ciclo a seleção roda, sem nenhuma remoção;
#   - o conjunto operacional permanece em 6 e o Ingress continua espelhando.
# Tempo: ~2,5 min
source "$(dirname "$0")/../lib/e2e.sh"

e2e_case "03 ciclo saudável"
net_ensure
stack_deploy

log "Modo Automatic"
stack_automatic

log "Ciclo 1 — proteção"
burn_protection_cycle
check "a proteção foi limpa ao fim da seleção" \
  "0" "$(count "$(call "$SELECTION" 'getProtectedValidators()(address[])')")"

log "Ciclo 2 — avaliação real, com os 6 nós no ar"
run_cycle "ciclo saudável"
check "a seleção rodou neste ciclo" \
  "sim" "$([ "$(events 'SelectionExecuted(address[])' "$CYCLE_START")" -ge 1 ] && echo sim || echo não)"
check "nenhum validador foi removido" \
  "0" "$(events 'OperationalValidatorRemoved(address)' "$CYCLE_START")"
check "o conjunto operacional segue com 6" \
  "6" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"
check "Ingress segue espelhando a lógica" \
  "$(call "$SELECTION" 'getValidators()(address[])')" "$(call "$INGRESS" 'getValidators()(address[])')"

e2e_report
