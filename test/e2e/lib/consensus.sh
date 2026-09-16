#!/usr/bin/env bash
#
# Transição do genesis para seleção de validadores por contrato, e observação do
# que o consenso do Besu de fato usa.
#
# É a peça que fecha a US1-3. Sem ela, todas as verificações sobre o Ingress são
# eth_call feitas pelo próprio teste: provam o que o contrato responde, não que
# alguém pergunte. Aqui a rede passa a perguntar.

E2E_GENESIS="${COMPOSE_DIR}/networkFiles/genesis.json"

# Modo de seleção que o genesis em vigor determina para o bloco atual.
# Uma transição só conta depois do bloco em que entra.
net_selection_mode() {
  local head
  head=$(blk)
  jq -r --argjson h "$head" '
    [(.config.transitions.qbft // [])[] | select(.block <= $h)] | last
    | if . == null then "blockheader" else .validatorselectionmode end
  ' "$E2E_GENESIS" 2>/dev/null || echo "desconhecido"
}

# Endereço do contrato que o genesis manda o Besu consultar, ou vazio.
net_validator_contract() {
  jq -r '[(.config.transitions.qbft // [])[] | .validatorcontractaddress // empty] | last // ""' \
    "$E2E_GENESIS" 2>/dev/null
}

# A rede ficou apontando para o Ingress de um caso específico? Então ela não
# serve para mais ninguém: os outros casos implantam pilhas novas, e um deles
# (05, 06) registra como operacional endereços que não são nó nenhum. Em modo
# contrato isso injetaria validadores fantasmas no consenso e travaria a cadeia.
# Por isso a rede é destruída ao fim de todo caso que aplica transição — o
# net_ensure do caso seguinte a reconstrói, já de volta ao modo blockheader.
E2E_NET_DIRTY=0

_drop_dirty_net() {
  [ "$E2E_NET_DIRTY" = "1" ] || return 0
  printf '  a rede ficou em modo contrato apontando para o Ingress deste caso; derrubando\n'
  net_down
}

# Substitui o trap de net.sh, que sozinho só religa nós parados. Ordem
# importa: religar antes de derrubar mantém o comportamento de net.sh
# intacto para o caso que aborta antes de aplicar a transição.
trap '_restore_nodes; _drop_dirty_net' EXIT

# Aplica a transição QBFT do README (US1-3): escreve transitions.qbft no genesis
# apontando para o Ingress e reinicia os 6 nós.
#
# O bloco da transição é futuro por obrigação do Besu, e o Ingress precisa já
# ter código nele quando a cadeia chegar lá — daí a ordem: implantar, depois
# transicionar. O reinício simultâneo dos 6 nós para a cadeia enquanto durar,
# o que garante folga de sobra para todos subirem antes do bloco alvo.
#
# Alterar .config não muda o hash do bloco genesis, então o Besu aceita o
# arquivo novo sobre os dados que já existem — é o que torna a transição
# aplicável numa rede em produção, sem reiniciar a cadeia.
net_to_contract_mode() {
  local ingress="$1" offset="${2:-15}" target
  target=$(( $(blk) + offset ))
  log "Transição do genesis: seleção por contrato a partir do bloco ${target}"
  echo "  validatorcontractaddress=${ingress}"

  jq --argjson b "$target" --arg addr "$ingress" \
    '.config.transitions.qbft = ((.config.transitions.qbft // []) + [{
       "block": $b,
       "validatorselectionmode": "contract",
       "validatorcontractaddress": $addr
     }])' "$E2E_GENESIS" > "${E2E_GENESIS}.tmp" \
    && mv "${E2E_GENESIS}.tmp" "$E2E_GENESIS"

  E2E_NET_DIRTY=1
  echo "  reiniciando os 6 nós com o genesis novo"
  (cd "$COMPOSE_DIR" && docker compose restart >/dev/null 2>&1)

  local deadline=$(( $(date +%s) + 240 ))
  until [ "$(blk)" -ge "$((target + 2))" ]; do
    if [ "$(date +%s)" -ge "$deadline" ]; then
      printf '  \033[31mFALHA\033[0m a cadeia não passou do bloco %s em 4 minutos após a transição\n' "$target"
      (cd "$COMPOSE_DIR" && docker compose ps --format '  {{.Name}}\t{{.State}}\t{{.Status}}')
      docker logs besu-node0 2>&1 | tail -20
      exit 1
    fi
    sleep 2
  done
  echo "  transição em vigor no bloco $(blk)"
}

# Conjunto de validadores que o consenso está usando, normalizado para comparar
# com a saída de getValidators(). Em modo contrato esta é a resposta do Ingress
# lida pelo próprio Besu, não pelo teste.
qbft_validators() {
  lower "$(cast rpc qbft_getValidatorsByBlockNumber '"latest"' --rpc-url "$RPC" 2>/dev/null \
    | tr -d '[]" ' | tr ',' '\n' | grep '^0x' | sort | tr '\n' ' ')"
}

# Mesma normalização para a lista devolvida por getValidators(), de modo que as
# duas sejam comparáveis com check().
sorted_validators() {
  lower "$(call "$1" 'getValidators()(address[])' \
    | tr -d '[]" ' | tr ',' '\n' | grep '^0x' | sort | tr '\n' ' ')"
}

qbft_count() { qbft_validators | wc -w; }

# Espera a cadeia avançar $1 blocos a partir de agora, com teto.
advance_blocks() {
  local target=$(( $(blk) + $1 )) deadline=$(( $(date +%s) + 180 ))
  until [ "$(blk)" -ge "$target" ]; do
    if [ "$(date +%s)" -ge "$deadline" ]; then
      printf '  \033[31mFALHA\033[0m a cadeia não avançou %s blocos em 3 minutos\n' "$1"
      exit 1
    fi
    sleep 2
  done
}

# Endereços distintos que propuseram os últimos $1 blocos.
#
# É a verificação mais forte que existe aqui: qbft_getValidatorsByBlockNumber diz
# quem o nó *considera* validador, propor bloco é participar do consenso de fato.
# A janela precisa cobrir mais de uma volta do round-robin (6 blocos) para que a
# ausência de um proposer signifique exclusão, e não a vez dele ainda não ter
# chegado.
proposers_in_last() {
  local n="$1" head i
  head=$(blk)
  for ((i = 0; i < n; i++)); do
    cast block $((head - i)) --field miner --rpc-url "$RPC" 2>/dev/null
  done | tr 'A-F' 'a-f' | grep '^0x' | sort -u
}

# "sim"/"não" para uso direto em check(): o validador propôs algum dos últimos $2 blocos?
proposed_recently() {
  local who; who=$(lower "$1")
  if proposers_in_last "$2" | grep -q "$who"; then echo "sim"; else echo "não"; fi
}

# "sim"/"não": o endereço está no conjunto que o consenso usa agora?
qbft_has() {
  if qbft_validators | grep -q "$(lower "$1")"; then echo "sim"; else echo "não"; fi
}

# Conjunto de validadores segundo UM nó específico, perguntado de dentro do
# container dele.
#
# "os nós da rede passam a desconsiderar o validador removido" é plural, e só o
# besu-node0 publica RPC para o host. Um nó que continuasse tratando como
# validador quem o contrato removeu não apareceria em nenhuma verificação feita
# pela porta 8545 — apareceria aqui.
qbft_validators_on() {
  docker exec "$1" curl -s -m 5 -X POST -H 'Content-Type: application/json' \
    --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' \
    http://localhost:8545 2>/dev/null \
    | jq -r '.result // [] | .[]' 2>/dev/null | tr 'A-F' 'a-f' | sort | tr '\n' ' '
}

_squash() { echo "$*" | tr -s ' ' | sed 's/^ *//; s/ *$//'; }

# "sim" se todo nó no ar responde exatamente o conjunto esperado; senão, quais
# divergem — a mensagem de falha do check() já sai com o nome do nó culpado.
# Nós parados de propósito pelo caso ficam de fora: docker compose só lista os
# que estão rodando.
all_nodes_agree() {
  local esperado node atual divergentes=""
  esperado=$(_squash "$1")
  for node in $(cd "$COMPOSE_DIR" && docker compose ps --services --filter status=running 2>/dev/null); do
    atual=$(_squash "$(qbft_validators_on "$node")")
    [ "$atual" = "$esperado" ] || divergentes="${divergentes} ${node}"
  done
  if [ -z "$divergentes" ]; then echo "sim"; else echo "divergem:${divergentes}"; fi
}
