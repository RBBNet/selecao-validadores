#!/usr/bin/env bash
#
# Implantação da pilha de contratos sobre a rede que já estiver no ar.
#
# Cada caso implanta a sua própria pilha. É o que torna os casos independentes:
# um contrato recém-implantado tem conjunto operacional conhecido, mapa de
# proposers vazio e ciclo zerado, sem depender do que o caso anterior deixou.
# Custa segundos, contra minutos de uma rede nova.

# Implanta Admin, Organizations, Accounts, Nodes, ValidatorSelection e Ingress.
# Exporta ADMIN, ACCOUNTS, NODES, SELECTION e INGRESS.
stack_deploy() {
  log "Implantando a pilha real sobre o Besu"
  local out
  out=$(forge script test/e2e/scripts/DeployE2EStack.s.sol --rpc-url "$RPC" --broadcast --legacy 2>&1)
  ADMIN=$(echo "$out"     | grep -oP 'ADMIN=\K0x\w+')
  ACCOUNTS=$(echo "$out"  | grep -oP 'ACCOUNTS=\K0x\w+')
  NODES=$(echo "$out"     | grep -oP 'NODES=\K0x\w+')
  SELECTION=$(echo "$out" | grep -oP 'SELECTION=\K0x\w+')
  INGRESS=$(echo "$out"   | grep -oP 'INGRESS=\K0x\w+')
  if [ -z "${SELECTION:-}" ] || ! echo "$out" | grep -q "ONCHAIN EXECUTION COMPLETE"; then
    echo "$out" | tail -25; echo "  FALHA: deploy não concluiu"; exit 1
  fi
  echo "  ValidatorSelection=${SELECTION}  Ingress=${INGRESS}"
}

# Liga o modo Automatic e exporta NEXT com o bloco da próxima seleção.
#
# setOperationMode(Automatic) reprotege todos os operacionais e reinicia o ciclo,
# então o bloco alvo precisa ser lido depois da troca, nunca antes.
stack_automatic() {
  send "$SELECTION" 'setOperationMode(uint8)' 1
  check "modo passou para Automatic" "1" "$(call "$SELECTION" 'operationMode()(uint8)')"
  NEXT=$(call_uint "$SELECTION" 'nextSelectionBlock()(uint256)')
  echo "  próxima seleção no bloco ${NEXT} (atual $(blk))"
}
