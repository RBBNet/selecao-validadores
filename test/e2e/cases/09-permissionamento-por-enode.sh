#!/usr/bin/env bash
# @desc Funções por enode contra a pilha de permissionamento real: derivação de endereço e checagem de organização
#
# Objetivo: verificar as funções que recebem o identificador do nó por enode
# (chave pública) contra os contratos reais de permissionamento, sem dublês.
# Pré-condições: rede no ar; pilha implantada; administrador da organização 2 configurado.
# O que verifica:
#   - o endereço que o contrato deriva do enode é o do nó Besu real que propõe blocos;
#   - ativação/remoção por enode, por administrador de organização e por governança;
#   - as checagens de admin ativo e de organização (o nó pertence à mesma
#     organização de quem chama) contra AccountRulesV2Impl e NodeRulesV2Impl reais.
# Por que este caso existe: as funções por enode são as únicas cujo comportamento
# depende de verdade dos contratos de permissionamento reais. No forge test elas
# rodam contra dublês (AccountRulesV2Mock/NodeRulesV2Mock), que codificam a
# suposição sobre como os contratos reais respondem — é essa suposição que este
# caso confirma.
# Tempo: ~40 s
source "$(dirname "$0")/../lib/e2e.sh"

e2e_case "09 permissionamento por enode contra a pilha real"
net_ensure
stack_deploy

# Chave da conta anvil #9, o segundo administrador global da pilha (E2E_ORG2_ADMIN).
# Não é governança: o Admin só autoriza quem o implantou, então as chamadas dela
# passam mesmo pelo caminho de admin de organização.
ORG2_KEY=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6

log "Premissa: o segundo admin não é governança"
check "governança reconhece o deployer" "true" "$(call "$ADMIN" 'isAuthorized(address)(bool)' "$DEPLOYER")"
check "governança NÃO reconhece o admin da org 2" \
  "false" "$(call "$ADMIN" 'isAuthorized(address)(bool)' "$E2E_ORG2_ADMIN")"

log "Organizações lidas do AccountRulesV2Impl real"
ORG1=$(call "$ACCOUNTS" 'getAccount(address)((uint256,address,bytes32,bytes32,bool))' "$DEPLOYER" | tr -d '()' | cut -d, -f1 | num)
ORG2=$(call "$ACCOUNTS" 'getAccount(address)((uint256,address,bytes32,bytes32,bool))' "$E2E_ORG2_ADMIN" | tr -d '()' | cut -d, -f1 | num)
echo "  deployer -> org ${ORG1}   admin2 -> org ${ORG2}"
check "os dois admins globais estão em organizações diferentes" \
  "sim" "$([ -n "$ORG1" ] && [ -n "$ORG2" ] && [ "$ORG1" != "$ORG2" ] && echo sim || echo não)"
check "o admin da org 2 está ativo no contrato de contas" \
  "true" "$(call "$ACCOUNTS" 'isAccountActive(address)(bool)' "$E2E_ORG2_ADMIN")"

# ---------------------------------------------------------------------------
log "1. O endereço derivado do enode é o do validador real que propõe blocos"
# O enode vem do arquivo de chave de um nó Besu de verdade; o endereço esperado
# é o que o caso 01 mostrou estar propondo blocos no round-robin do QBFT.
read -r ENODE_HIGH ENODE_LOW <<< "$(enode_of node5)"
REAL="${V[5]}"
echo "  enodeHigh=${ENODE_HIGH}"
echo "  enodeLow =${ENODE_LOW}"
echo "  validador real esperado: ${REAL}"
check "a derivação local bate com o validador do .env (conferência cruzada)" \
  "$(lower "$REAL")" "$(lower "$(addr_of_enode "$ENODE_HIGH" "$ENODE_LOW")")"

# Tira o validador do conjunto e recoloca pelo enode: se o contrato derivar
# outro endereço, isEligible volta false e o caso falha aqui.
send "$SELECTION" 'removeEligibleValidatorByAddress(address)' "$REAL"
check "removido do conjunto de elegíveis pela governança" \
  "false" "$(call "$SELECTION" 'isEligible(address)(bool)' "$REAL")"
check "removeEligibleValidatorByAddress também tirou dos operacionais" \
  "false" "$(call "$SELECTION" 'isOperational(address)(bool)' "$REAL")"

send "$SELECTION" 'addEligibleValidator(bytes32,bytes32,bool)' "$ENODE_HIGH" "$ENODE_LOW" true
check "readicionado PELO ENODE: o contrato derivou o endereço do validador real" \
  "true" "$(call "$SELECTION" 'isEligible(address)(bool)' "$REAL")"
check "e foi ativado como operacional" \
  "true" "$(call "$SELECTION" 'isOperational(address)(bool)' "$REAL")"
check "conjunto operacional de volta a 6" \
  "6" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"

# ---------------------------------------------------------------------------
log "2. Registro dos nós no NodeRulesV2Impl real"
# Dois nós sintéticos: um na organização do admin2, outro na do deployer. O que
# está sob teste aqui é a checagem de organização, não a identidade do nó.
NODE_A_HIGH=0xa1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1
NODE_A_LOW=0xa2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2
NODE_B_HIGH=0xb1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1
NODE_B_LOW=0xb2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2
ADDR_A=$(addr_of_enode "$NODE_A_HIGH" "$NODE_A_LOW")
ADDR_B=$(addr_of_enode "$NODE_B_HIGH" "$NODE_B_LOW")

# Tipo do nó (uint8): NodeType.Validator = 1, no enum de NodeRulesV2.
send "$NODES" 'addNode(bytes32,bytes32,uint8,string,uint256)' \
  "$NODE_A_HIGH" "$NODE_A_LOW" 1 "no-da-org2" "$ORG2"
send "$NODES" 'addNode(bytes32,bytes32,uint8,string,uint256)' \
  "$NODE_B_HIGH" "$NODE_B_LOW" 1 "no-da-org1" "$ORG1"
check "nó A registrado e ativo no NodeRules real" \
  "true" "$(call "$NODES" 'isNodeActive(bytes32,bytes32)(bool)' "$NODE_A_HIGH" "$NODE_A_LOW")"
check "nó B registrado e ativo no NodeRules real" \
  "true" "$(call "$NODES" 'isNodeActive(bytes32,bytes32)(bool)' "$NODE_B_HIGH" "$NODE_B_LOW")"

log "3. Elegibilidade concedida pela governança, também por enode"
send "$SELECTION" 'addEligibleValidator(bytes32,bytes32,bool)' "$NODE_A_HIGH" "$NODE_A_LOW" false
send "$SELECTION" 'addEligibleValidator(bytes32,bytes32,bool)' "$NODE_B_HIGH" "$NODE_B_LOW" false
check "nó A elegível, ainda não operacional" "true false" \
  "$(call "$SELECTION" 'isEligible(address)(bool)' "$ADDR_A") $(call "$SELECTION" 'isOperational(address)(bool)' "$ADDR_A")"
check "nó B elegível, ainda não operacional" "true false" \
  "$(call "$SELECTION" 'isEligible(address)(bool)' "$ADDR_B") $(call "$SELECTION" 'isOperational(address)(bool)' "$ADDR_B")"

# ---------------------------------------------------------------------------
log "4. Admin de organização ativa um nó da PRÓPRIA organização"
# Exercita, contra os contratos reais, as validações de que quem chama é um
# administrador ativo e de que o nó pertence à mesma organização do admin.
send_as "$ORG2_KEY" "$SELECTION" 'addOperationalValidator(bytes32,bytes32)' "$NODE_A_HIGH" "$NODE_A_LOW"
check "o admin da org 2 ativou o nó da org 2" \
  "true" "$(call "$SELECTION" 'isOperational(address)(bool)' "$ADDR_A")"
check "conjunto operacional foi a 7" \
  "7" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"

log "5. Admin de organização NÃO ativa nó de outra organização"
check "ativar nó da org 1 pelo admin da org 2 reverte com NotLocalNode" \
  "sim" "$(reverts_with_from "$E2E_ORG2_ADMIN" 'NotLocalNode(bytes32,bytes32)' \
    "$SELECTION" 'addOperationalValidator(bytes32,bytes32)' "$NODE_B_HIGH" "$NODE_B_LOW")"
check "o nó B seguiu fora do conjunto operacional" \
  "false" "$(call "$SELECTION" 'isOperational(address)(bool)' "$ADDR_B")"

log "6. Conta sem papel administrativo é barrada pelo AccountRules real"
STRANGER=0x000000000000000000000000000000000000dEaD
check "conta sem papel reverte com UnauthorizedAccess" \
  "sim" "$(reverts_with_from "$STRANGER" 'UnauthorizedAccess(address)' \
    "$SELECTION" 'addOperationalValidator(bytes32,bytes32)' "$NODE_A_HIGH" "$NODE_A_LOW")"

# ---------------------------------------------------------------------------
log "7. Remoção por admin de organização (removeOperationalValidatorByAdmin)"
send_as "$ORG2_KEY" "$SELECTION" 'removeOperationalValidatorByAdmin(bytes32,bytes32)' \
  "$NODE_A_HIGH" "$NODE_A_LOW"
check "o admin da org 2 removeu o próprio nó do conjunto operacional" \
  "false" "$(call "$SELECTION" 'isOperational(address)(bool)' "$ADDR_A")"
check "o nó A continua elegível" \
  "true" "$(call "$SELECTION" 'isEligible(address)(bool)' "$ADDR_A")"
check "conjunto operacional de volta a 6" \
  "6" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"

log "8. Remoções por enode pela governança"
send "$SELECTION" 'removeEligibleValidator(bytes32,bytes32)' "$NODE_B_HIGH" "$NODE_B_LOW"
check "nó B deixou de ser elegível" \
  "false" "$(call "$SELECTION" 'isEligible(address)(bool)' "$ADDR_B")"

send "$SELECTION" 'addOperationalValidator(bytes32,bytes32)' "$NODE_A_HIGH" "$NODE_A_LOW"
check "governança reativou o nó A por enode" \
  "true" "$(call "$SELECTION" 'isOperational(address)(bool)' "$ADDR_A")"
send "$SELECTION" 'removeOperationalValidator(bytes32,bytes32)' "$NODE_A_HIGH" "$NODE_A_LOW"
check "governança removeu o nó A do operacional por enode" \
  "false" "$(call "$SELECTION" 'isOperational(address)(bool)' "$ADDR_A")"
check "os 6 validadores reais seguem operacionais ao final" \
  "6" "$(count "$(call "$SELECTION" 'getValidators()(address[])')")"

e2e_report
