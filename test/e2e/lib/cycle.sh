#!/usr/bin/env bash
#
# Monitoramento denso e execução de ciclos de seleção.

# Envia executeMonitoring até a cadeia atingir a altura alvo.
#
# Precisa ser denso: executeMonitoring credita apenas o proposer do bloco em que
# a transação entra (lastBlockProposedBy[block.coinbase]) e ignora chamadas
# repetidas no mesmo bloco. Se o monitoramento pular blocos, validadores
# saudáveis deixam de ser creditados e a seleção os remove por engano.
# Por isso o envio é assíncrono com nonce explícito, mais rápido que o bloco.
# Dispara exatamente uma transação por bloco novo: enviar às cegas empilha
# transações no pool, o Besu as inclui em lote e sobram blocos sem monitoramento.
monitor_until() {
  local target="$1"
  local last=0 head nonce
  # Sem teto o laço gira para sempre se a cadeia parar (quorum perdido) ou se a
  # rede for recriada por baixo — foi assim que uma execução ficou pendurada.
  local deadline=$(( $(date +%s) + 420 ))
  while :; do
    if [ "$(date +%s)" -ge "$deadline" ]; then
      printf '  \033[31mFALHA\033[0m cadeia não alcançou o bloco %s em 7 minutos (parou de produzir?)\n' "$target"
      exit 1
    fi
    head=$(blk)
    [ "$head" -ge "$target" ] && break
    if [ "$head" -gt "$last" ]; then
      nonce=$(cast nonce "$DEPLOYER" --rpc-url "$RPC" --block pending 2>/dev/null)
      cast send "$SELECTION" 'executeMonitoring()' \
        --private-key "$PRIVATE_KEY" --rpc-url "$RPC" --legacy \
        --gas-limit "$GAS_LIMIT" --async --nonce "$nonce" >/dev/null 2>&1
      last="$head"
    fi
    sleep 0.3
  done
  # Espera a fila drenar para que os envios síncronos seguintes não colidam.
  local n=0
  until [ "$(cast nonce "$DEPLOYER" --rpc-url "$RPC" --block pending 2>/dev/null || echo 0)" \
        -le "$(cast nonce "$DEPLOYER" --rpc-url "$RPC" 2>/dev/null || echo 1)" ] || [ "$n" -ge 30 ]; do
    sleep 2; n=$((n + 1))
  done
}

# Mede quantos blocos da janela receberam monitoramento. Cobertura baixa faz a
# seleção remover validadores saudáveis, então isso é verificado explicitamente.
coverage() {
  cast logs --from-block "$1" --to-block "$2" --address "$SELECTION" \
    "MonitorExecuted(address,uint256)" --rpc-url "$RPC" 2>/dev/null \
    | grep -oP 'blockNumber: \K\d+' | sort -un | wc -l
}

# Quantas vezes o evento $1 foi emitido pela lógica desde o bloco $2.
events() {
  cast logs --from-block "$2" --to-block latest --address "$SELECTION" "$1" \
    --rpc-url "$RPC" 2>/dev/null | grep -c 'blockNumber:'
}

# Em quantos blocos distintos o evento $1 apareceu desde o bloco $2. Serve para
# provar que um lote de remoções saiu todo na mesma seleção, e não aos poucos.
event_blocks() {
  cast logs --from-block "$2" --to-block latest --address "$SELECTION" "$1" \
    --rpc-url "$RPC" 2>/dev/null | grep -oP 'blockNumber: \K\d+' | sort -un | wc -l
}

# Roda um ciclo inteiro: monitora densamente até o bloco de seleção ($NEXT),
# dispara a seleção e confere a cobertura. Exporta CYCLE_START (para consultar os
# eventos do ciclo) e atualiza NEXT com o alvo do ciclo seguinte.
# O rótulo opcional em $1 aparece no log para separar os ciclos de um caso.
run_cycle() {
  local label="${1:-ciclo}" cov total target="$NEXT"
  require_contracts
  echo "  ${label}: monitorando até o bloco ${target} (atual $(blk))"
  CYCLE_START=$(blk)
  monitor_until "$target"
  send "$SELECTION" 'executeMonitoring()'
  # A janela de coverage() é inclusiva nas duas pontas, então o total é a
  # diferença mais um — sem isso a cobertura imprime coisas como "30/29".
  cov=$(coverage "$CYCLE_START" "$target"); total=$((target - CYCLE_START + 1))
  echo "  cobertura do monitoramento: ${cov}/${total} blocos"
  # O limite é 90%, não 80%: o monitoramento denso é o que evita falsos positivos
  # de inatividade. Um validador só é considerado inativo após ficar
  # blocksWithoutProposeThreshold (18) blocos sem propor — o equivalente a 3
  # rodadas completas do round-robin de 6 validadores. Uma lacuna de 20% na
  # cobertura da janela poderia engolir as propostas recentes de um validador
  # saudável e fazer a seleção derrubá-lo sem defeito no contrato. Na prática a
  # cobertura observada fica em 97-100%.
  check "${label}: monitoramento cobriu ao menos 90% dos blocos" \
    "sim" "$([ "$cov" -ge $((total * 9 / 10)) ] && echo sim || echo não)"
  NEXT=$(call_uint "$SELECTION" 'nextSelectionBlock()(uint256)')
}

# Queima o ciclo de proteção.
#
# Tanto o construtor quanto setOperationMode(Automatic) põem todo o conjunto
# operacional em protectedValidators, e _isInactive ignora quem está protegido.
# A proteção só é limpa ao fim de uma seleção, então nenhum cenário de remoção
# mede coisa alguma antes de um ciclo completo ter passado.
burn_protection_cycle() {
  run_cycle "ciclo de proteção"
}
