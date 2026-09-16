#!/usr/bin/env bash
#
# Ciclo de vida da rede Besu QBFT em Docker.
#
# Esta é a parte cara do e2e (minutos): por isso a rede é reaproveitada entre
# casos e só é recriada quando não existe, está inconsistente ou o usuário pede.

# Nós parados pelo caso em execução, religados no EXIT mesmo se o caso abortar.
# Sem isso, um caso que falha no meio deixa a rede mutilada e o caso seguinte
# falha por um motivo que não é o dele.
E2E_STOPPED_NODES=""

_restore_nodes() {
  [ -z "$E2E_STOPPED_NODES" ] && return 0
  printf '  religando nós parados por este caso:%s\n' "$E2E_STOPPED_NODES"
  # shellcheck disable=SC2086
  (cd "$COMPOSE_DIR" && docker compose start $E2E_STOPPED_NODES >/dev/null 2>&1)
  E2E_STOPPED_NODES=""
}
trap _restore_nodes EXIT

node_stop() {
  E2E_STOPPED_NODES="${E2E_STOPPED_NODES} $*"
  # shellcheck disable=SC2086
  (cd "$COMPOSE_DIR" && docker compose stop $* >/dev/null 2>&1)
}

node_start() {
  # shellcheck disable=SC2086
  (cd "$COMPOSE_DIR" && docker compose start $* >/dev/null 2>&1)
  local remaining="" n
  for n in $E2E_STOPPED_NODES; do
    case " $* " in *" $n "*) ;; *) remaining="${remaining} ${n}" ;; esac
  done
  E2E_STOPPED_NODES="$remaining"
}

# Espera a cadeia passar de uma altura, com teto.
_wait_height() {
  local target="$1" limit="${2:-90}" n=0
  until [ "$(blk)" -ge "$target" ] || [ "$n" -ge "$limit" ]; do sleep 2; n=$((n + 1)); done
  [ "$(blk)" -ge "$target" ]
}

# A rede está no ar, é a nossa e está produzindo blocos?
net_alive() {
  [ "$(cast chain-id --rpc-url "$RPC" 2>/dev/null)" = "1337" ] || return 1
  local before after
  before=$(blk); sleep 5; after=$(blk)
  [ "$after" -gt "$before" ]
}

net_down() {
  (cd "$COMPOSE_DIR" && docker compose down -v >/dev/null 2>&1)
}

# Recria tudo do zero. O setup gera chaves e genesis novos a cada execução,
# então os volumes da rodada anterior precisam morrer junto: Besu recusa subir
# com "Supplied genesis block does not match chain data stored in /data" e entra
# em loop de restart.
net_reset() {
  log "Recriando a rede Besu QBFT (6 nós)"
  net_down
  bash "${COMPOSE_DIR}/setup.sh" >/dev/null 2>&1
  (cd "$COMPOSE_DIR" && docker compose up -d --build >/dev/null 2>&1)
  if ! _wait_height 3 90; then
    echo "  FALHA: rede não produziu blocos em 3 minutos"
    (cd "$COMPOSE_DIR" && docker compose ps --format '  {{.Name}}\t{{.State}}\t{{.Status}}')
    echo "  --- últimas linhas do besu-node0 ---"
    docker logs besu-node0 2>&1 | tail -15
    exit 1
  fi
}

# Garante uma rede utilizável e exporta E2E_VALIDATORS / V[].
#
# E2E_FRESH_NET=1 força a recriação. Sem isso, uma rede já no ar é reaproveitada
# — é o que torna viável rodar um caso isolado em segundos em vez de minutos.
net_ensure() {
  if [ "${E2E_FRESH_NET:-0}" = "1" ] || ! net_alive; then
    net_reset
  fi

  # A porta 8545 pode estar ocupada por outra cadeia; sem esta checagem o caso
  # seguiria conversando com ela e falharia muito mais adiante, sem explicação.
  local chain_id
  chain_id=$(cast chain-id --rpc-url "$RPC" 2>/dev/null)
  if [ "$chain_id" != "1337" ]; then
    echo "  FALHA: ${RPC} responde com chainId ${chain_id}, esperado 1337."
    echo "  Outra rede está ocupando a porta? Use E2E_RPC para apontar para outra."
    exit 1
  fi

  set -a; . "${COMPOSE_DIR}/.env"; set +a
  IFS=',' read -r -a V <<< "$E2E_VALIDATORS"

  # O .env é gerado pelo setup.sh. Se sobrou de uma rede anterior, os endereços
  # não batem com os validadores vivos e todo caso falharia por um motivo falso.
  local live env_set
  live=$(lower "$(cast rpc qbft_getValidatorsByBlockNumber '"latest"' --rpc-url "$RPC" 2>/dev/null | tr -d '[]" ' | tr ',' '\n' | sort | tr '\n' ',')")
  env_set=$(lower "$(echo "$E2E_VALIDATORS" | tr ',' '\n' | sort | tr '\n' ',')")
  if [ "$live" != "$env_set" ]; then
    echo "  FALHA: test/e2e/docker/besu/.env não corresponde aos validadores da rede no ar."
    echo "         .env:  ${env_set}"
    echo "         cadeia: ${live}"
    echo "  Rode com --fresh para recriar a rede junto com o .env."
    exit 1
  fi

  echo "  rede no bloco $(blk) (chainId 1337, ${#V[@]} validadores QBFT)"
}

# Aborta se a rede foi recriada por baixo durante a execução: sem isto, todas as
# verificações seguintes falhariam sem explicação.
require_contracts() {
  if [ "$(cast code "$SELECTION" --rpc-url "$RPC" 2>/dev/null)" = "0x" ]; then
    printf '  \033[31mFALHA\033[0m a rede foi recriada durante a execução: não há código em %s\n' "$SELECTION"
    printf '        outra execução do e2e rodando em paralelo?\n'
    exit 1
  fi
}
