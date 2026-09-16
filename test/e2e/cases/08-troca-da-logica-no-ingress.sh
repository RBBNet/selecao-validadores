#!/usr/bin/env bash
# @desc Troca da lógica registrada no Ingress: o único mecanismo de atualização do sistema
#
# Objetivo: exercitar o único mecanismo de atualização da lógica do sistema — a
# troca do contrato registrado no Ingress, com a rede no ar — incluindo as
# validações que barram trocas inválidas e o fallback de segurança.
# Pré-condições: rede no ar; pilha implantada.
# O que verifica:
#   - o Ingress espelha a lógica original (6 validadores);
#   - trocas inválidas revertem com os erros esperados (SameAddress,
#     InvalidAddress, InvalidValidatorSelectionContract);
#   - a troca efetiva muda a resposta do Ingress sem parar a cadeia;
#   - sem lógica registrada, o Ingress devolve o proponente do bloco
#     (block.coinbase) em vez de lista vazia, para não travar o consenso;
#   - o registro volta para a lógica original.
# Tempo: ~25 s
source "$(dirname "$0")/../lib/e2e.sh"

e2e_case "08 troca da lógica no Ingress"
net_ensure
stack_deploy

ORIGINAL=$(call "$SELECTION" 'getValidators()(address[])')
check "Ingress responde a lógica original (6 validadores)" \
  "$ORIGINAL" "$(call "$INGRESS" 'getValidators()(address[])')"

log "Segunda instância da lógica, com conjunto propositalmente menor"
# Conjunto menor para que a resposta do Ingress mude de forma observável.
export E2E_ADMIN="$ADMIN" E2E_ACCOUNTS="$ACCOUNTS" E2E_NODES="$NODES"
export E2E_SPARE_VALIDATORS="${V[0]},${V[1]},${V[2]},${V[3]}"
OUT=$(forge script test/e2e/scripts/DeployE2ESpareSelection.s.sol --rpc-url "$RPC" --broadcast --legacy 2>&1)
SPARE=$(echo "$OUT" | grep -oP 'SPARE_SELECTION=\K0x\w+')
if [ -z "${SPARE:-}" ] || ! echo "$OUT" | grep -q "ONCHAIN EXECUTION COMPLETE"; then
  echo "$OUT" | tail -25; echo "  FALHA: deploy da segunda instância não concluiu"; exit 1
fi
echo "  lógica reserva=${SPARE}"
check "a lógica reserva tem 4 operacionais" \
  "4" "$(count "$(call "$SPARE" 'getValidators()(address[])')")"

log "Validações que barram uma troca inválida"
check "trocar para o endereço já registrado reverte com SameAddress" \
  "sim" "$(reverts_with 'SameAddress(address)' \
    "$INGRESS" 'updateValidatorSelectionContract(address)' "$SELECTION")"
check "trocar para o endereço zero reverte com InvalidAddress" \
  "sim" "$(reverts_with 'InvalidAddress()' \
    "$INGRESS" 'updateValidatorSelectionContract(address)' \
    0x0000000000000000000000000000000000000000)"
check "trocar para um contrato sem getValidators reverte com InvalidValidatorSelectionContract" \
  "sim" "$(reverts_with 'InvalidValidatorSelectionContract(address)' \
    "$INGRESS" 'updateValidatorSelectionContract(address)' "$ADMIN")"
check "trocar para um endereço sem código reverte com InvalidValidatorSelectionContract" \
  "sim" "$(reverts_with 'InvalidValidatorSelectionContract(address)' \
    "$INGRESS" 'updateValidatorSelectionContract(address)' \
    0x00000000000000000000000000000000000000ff)"

log "Troca efetiva, com a rede no ar"
send "$INGRESS" 'updateValidatorSelectionContract(address)' "$SPARE"
check "Ingress passou a apontar para a lógica reserva" \
  "$(lower "$SPARE")" "$(lower "$(call "$INGRESS" 'validatorSelectionContract()(address)')")"
check "Ingress responde o conjunto da nova lógica" \
  "$(call "$SPARE" 'getValidators()(address[])')" "$(call "$INGRESS" 'getValidators()(address[])')"
check "a resposta do Ingress mudou de fato" \
  "sim" "$([ "$(call "$INGRESS" 'getValidators()(address[])')" != "$ORIGINAL" ] && echo sim || echo não)"
check "a lógica antiga continua no ar, intocada" \
  "$ORIGINAL" "$(call "$SELECTION" 'getValidators()(address[])')"
check "a cadeia não parou durante a troca" \
  "sim" "$(B=$(blk); sleep 6; [ "$(blk)" -gt "$B" ] && echo sim || echo não)"

log "Rede de segurança: sem lógica registrada o Ingress não devolve lista vazia"
# Uma lista vazia deixaria o Besu sem validadores. O fallback para block.coinbase
# mantém o consenso de pé enquanto a governança conserta o registro.
send "$INGRESS" 'removeValidatorSelectionContract()'
check "sem lógica registrada, o Ingress devolve exatamente um endereço" \
  "1" "$(count "$(call "$INGRESS" 'getValidators()(address[])')")"

log "Voltando o registro para a lógica original"
send "$INGRESS" 'updateValidatorSelectionContract(address)' "$SELECTION"
check "Ingress voltou a espelhar a lógica original" \
  "$ORIGINAL" "$(call "$INGRESS" 'getValidators()(address[])')"

e2e_report
