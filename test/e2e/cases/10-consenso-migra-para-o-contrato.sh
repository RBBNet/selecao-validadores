#!/usr/bin/env bash
# @desc A informação de quem é validador migra do cabeçalho do bloco para o contrato (US1-3)
#
# Objetivo: verificar a transição de gênesis que faz o consenso passar a ler o
# conjunto de validadores do contrato em vez do cabeçalho do bloco (US1-3).
# Pré-condições: rede no ar em modo "blockheader"; pilha implantada.
# O que verifica:
#   - antes da transição, alterações no contrato são ignoradas pelo consenso;
#   - aplicada a transição, o Besu passa a ler exatamente o que o Ingress responde
#     (o validador removido sai do consenso e para de propor, com o container no ar);
#   - reincluído no contrato, o nó volta ao consenso e a produzir blocos.
# Por que este caso é diferente dos demais: os outros consultam o Ingress via
# eth_call do próprio teste (provam o que o contrato responde). Aqui é o Besu que
# consulta o contrato — prova o que o consenso efetivamente usa.
# Tempo: ~3,5 min
source "$(dirname "$0")/../lib/e2e.sh"

e2e_case "10 o consenso migra do cabeçalho para o contrato"
net_ensure
check "a rede começa com a seleção por cabeçalho de bloco" \
  "blockheader" "$(net_selection_mode)"
check "o genesis não aponta para contrato nenhum" "" "$(net_validator_contract)"

stack_deploy
ALVO="${V[5]}"

log "1. Antes da transição o contrato não manda no consenso"
check "consenso e contrato partem do mesmo conjunto de 6" \
  "$(sorted_validators "$SELECTION")" "$(qbft_validators)"

# Remoção manual pela governança: o mesmo efeito que a seleção automática
# produziria, sem o custo de dois ciclos. O que está sob teste aqui é de onde o
# Besu lê o conjunto, não como o conjunto é decidido — isso é o caso 11.
send "$SELECTION" 'removeOperationalValidatorByAddress(address)' "$ALVO"
check "o contrato passou a 5 operacionais" \
  "5" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"
check "o Ingress espelha os 5" \
  "$(sorted_validators "$SELECTION")" "$(sorted_validators "$INGRESS")"
check "o consenso seguiu com 6: ainda lê o cabeçalho do bloco" "6" "$(qbft_count)"
check "o alvo continua no conjunto do consenso" "sim" "$(qbft_has "$ALVO")"

advance_blocks 14
check "e continua propondo blocos" "sim" "$(proposed_recently "$ALVO" 14)"

# ---------------------------------------------------------------------------
log "2. A transição do genesis (US1-3), sem tocar em nenhum contrato"
net_to_contract_mode "$INGRESS"
check "o modo em vigor passou a ser por contrato" "contract" "$(net_selection_mode)"
check "o genesis aponta para o Ingress" \
  "$(lower "$INGRESS")" "$(lower "$(net_validator_contract)")"

log "3. Agora o consenso usa o conjunto do contrato"
check "o Besu lê exatamente o que o Ingress responde" \
  "$(sorted_validators "$INGRESS")" "$(qbft_validators)"
check "o consenso caiu para 5 validadores" "5" "$(qbft_count)"
check "o alvo saiu do conjunto do consenso" "não" "$(qbft_has "$ALVO")"
check "os 6 nós da rede leem o mesmo conjunto, não só o que publica RPC" \
  "sim" "$(all_nodes_agree "$(sorted_validators "$INGRESS")")"

advance_blocks 14
check "o alvo parou de propor blocos, com o container dele no ar o tempo todo" \
  "não" "$(proposed_recently "$ALVO" 14)"
check "a cadeia continua produzindo com 5" \
  "sim" "$(B=$(blk); sleep 6; [ "$(blk)" -gt "$B" ] && echo sim || echo não)"

# ---------------------------------------------------------------------------
log "4. O caminho de volta: reincluir no contrato devolve o nó ao consenso"
send "$SELECTION" 'addOperationalValidatorByAddress(address)' "$ALVO"
check "o contrato voltou a 6 operacionais" \
  "6" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"
advance_blocks 3
check "o consenso voltou a 6 validadores" "6" "$(qbft_count)"
check "o alvo está de volta ao conjunto do consenso" "sim" "$(qbft_has "$ALVO")"
check "os 6 nós voltaram a concordar" \
  "sim" "$(all_nodes_agree "$(sorted_validators "$INGRESS")")"
advance_blocks 14
check "o alvo voltou a propor blocos" "sim" "$(proposed_recently "$ALVO" 14)"

e2e_report
