#!/usr/bin/env bash
# @desc Nó inoperante é removido do consenso pela seleção automática e volta quando o partícipe pede a reinclusão
#
# Objetivo: percorrer o fluxo completo do mecanismo com o consenso lendo o
# contrato — o mesmo cenário do caso 04, porém observado no consenso real do Besu.
# Pré-condições: rede no ar em modo "blockheader"; pilha implantada; o enode de
# besu-node5 registrado como nó da organização 2.
# O que verifica:
#   - após a transição, um nó cujo container foi parado é removido pelo contrato e
#     deixa o conjunto do consenso; os demais nós concordam entre si;
#   - com o container de volta, o partícipe (admin da própria organização) pede a
#     reinclusão por enode, sem passar pela governança;
#   - o nó reincluído sobrevive a uma seleção sem proteção, provando que voltou a
#     produzir blocos de fato.
# Diferença para o caso 04: lá a remoção é observada na lista do contrato; aqui,
# no consenso — o nó para de propor porque a rede deixou de considerá-lo
# validador, não porque o container está parado.
# Tempo: ~6 min
source "$(dirname "$0")/../lib/e2e.sh"

# Chave da conta anvil #9, admin global da organização 2 (E2E_ORG2_ADMIN). Não é
# governança: a reinclusão passa pelo caminho do partícipe, que é o descrito no
# README para quem teve o próprio nó removido.
ORG2_KEY=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6

e2e_case "11 inatividade real removida do consenso e retorno"
net_ensure
check "a rede começa com a seleção por cabeçalho de bloco" \
  "blockheader" "$(net_selection_mode)"

stack_deploy
ALVO="${V[5]}"
read -r ENODE_HIGH ENODE_LOW <<< "$(enode_of node5)"
check "o enode de besu-node5 deriva no endereço do validador (conferência cruzada)" \
  "$(lower "$ALVO")" "$(lower "$(addr_of_enode "$ENODE_HIGH" "$ENODE_LOW")")"

log "Registrando besu-node5 como nó da organização 2 no NodeRules real"
# Sem isso o partícipe não consegue pedir a reinclusão do próprio nó:
# addOperationalValidator exige que o enode pertença à organização de quem chama.
ORG2=$(call "$ACCOUNTS" 'getAccount(address)((uint256,address,bytes32,bytes32,bool))' \
  "$E2E_ORG2_ADMIN" | tr -d '()' | cut -d, -f1 | num)
send "$NODES" 'addNode(bytes32,bytes32,uint8,string,uint256)' \
  "$ENODE_HIGH" "$ENODE_LOW" 1 "besu-node5" "$ORG2"
check "besu-node5 está ativo no NodeRules, na organização ${ORG2}" \
  "true" "$(call "$NODES" 'isNodeActive(bytes32,bytes32)(bool)' "$ENODE_HIGH" "$ENODE_LOW")"

# ---------------------------------------------------------------------------
log "Transição: o consenso passa a perguntar ao contrato"
# Antes do modo Automatic, para que a janela de monitoramento comece depois de a
# cadeia já estar estável no modo novo — setOperationMode reinicia o ciclo.
net_to_contract_mode "$INGRESS"
check "o Besu lê o conjunto do Ingress" \
  "$(sorted_validators "$INGRESS")" "$(qbft_validators)"
check "os 6 nós reais estão no consenso" "6" "$(qbft_count)"

log "Modo Automatic"
stack_automatic

log "Ciclo 1 — proteção (nada é avaliado enquanto o conjunto está protegido)"
burn_protection_cycle

# ---------------------------------------------------------------------------
log "Ciclo 2 — com besu-node5 realmente parado"
echo "  parando besu-node5 (${ALVO})"
node_stop besu-node5
run_cycle "ciclo com o nó parado"

check "a seleção removeu o nó do conjunto operacional" \
  "false" "$(call "$SELECTION" 'isOperational(address)(bool)' "$ALVO")"
check "o nó continua elegível" \
  "true" "$(call "$SELECTION" 'isEligible(address)(bool)' "$ALVO")"
check "o contrato responde 5 operacionais" \
  "5" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"

log "O que os outros nós passaram a enxergar"
advance_blocks 3
check "o consenso caiu para 5 validadores" "5" "$(qbft_count)"
check "o nó parado saiu do conjunto do consenso" "não" "$(qbft_has "$ALVO")"
check "o consenso segue igual ao que o Ingress responde" \
  "$(sorted_validators "$INGRESS")" "$(qbft_validators)"
check "os 5 nós que restaram concordam entre si, não só o que publica RPC" \
  "sim" "$(all_nodes_agree "$(sorted_validators "$INGRESS")")"
check "a cadeia continua produzindo com 5" \
  "sim" "$(B=$(blk); sleep 6; [ "$(blk)" -gt "$B" ] && echo sim || echo não)"

# ---------------------------------------------------------------------------
log "O nó volta ao ar e o partícipe pede a reinclusão"
node_start besu-node5
advance_blocks 5
check "de volta ao ar, mas ainda fora do consenso" "não" "$(qbft_has "$ALVO")"
check "e sem propor bloco nenhum" "não" "$(proposed_recently "$ALVO" 12)"

# O caminho do README: o partícipe que teve o nó removido pede a reinclusão pelo
# enode, com o admin da própria organização. Não passa pela governança.
send_as "$ORG2_KEY" "$SELECTION" 'addOperationalValidator(bytes32,bytes32)' \
  "$ENODE_HIGH" "$ENODE_LOW"
check "o admin da organização reincluiu o próprio nó" \
  "true" "$(call "$SELECTION" 'isOperational(address)(bool)' "$ALVO")"
check "quem é reincluído entra protegido, sem ser avaliado no ciclo em curso" \
  "true" "$(call "$SELECTION" 'isProtected(address)(bool)' "$ALVO")"
check "o contrato voltou a 6 operacionais" \
  "6" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"

advance_blocks 3
check "o consenso voltou a 6 validadores" "6" "$(qbft_count)"
check "o nó está de volta ao conjunto do consenso" "sim" "$(qbft_has "$ALVO")"
check "os 6 nós voltaram a concordar com o conjunto do contrato" \
  "sim" "$(all_nodes_agree "$(sorted_validators "$INGRESS")")"

# ---------------------------------------------------------------------------
# Estar de volta ao consenso é apenas o estado imediato. O que prova que o nó
# voltou a funcionar é sustentar-se: a proteção da reinclusão vale só até o fim
# do ciclo em curso; a partir daí o nó é avaliado como qualquer outro. Se voltou
# só no papel e não propõe blocos na janela monitorada, a seleção o remove de novo.
log "Ciclo 3 — queima da proteção que a reinclusão concedeu"
run_cycle "ciclo de queima"
check "a seleção não removeu ninguém neste ciclo" \
  "0" "$(events 'OperationalValidatorRemoved(address)' "$CYCLE_START")"
check "o nó reincluído perdeu a proteção" \
  "false" "$(call "$SELECTION" 'isProtected(address)(bool)' "$ALVO")"
check "e segue operacional" \
  "true" "$(call "$SELECTION" 'isOperational(address)(bool)' "$ALVO")"

log "Ciclo 4 — o nó é avaliado sem proteção nenhuma"
run_cycle "ciclo de confirmação"
check "sobreviveu à seleção por atividade própria" \
  "true" "$(call "$SELECTION" 'isOperational(address)(bool)' "$ALVO")"
check "a seleção não removeu ninguém neste ciclo" \
  "0" "$(events 'OperationalValidatorRemoved(address)' "$CYCLE_START")"
check "o contrato segue com 6 operacionais" \
  "6" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"
check "o consenso segue com 6" "6" "$(qbft_count)"
check "os 6 nós seguem de acordo" \
  "sim" "$(all_nodes_agree "$(sorted_validators "$INGRESS")")"
check "e o nó propôs blocos na janela que acabou de ser monitorada" \
  "sim" "$(proposed_recently "$ALVO" 14)"

e2e_report
