#!/bin/bash
#
# Entrypoint do nó Besu QBFT.
#
# Variáveis esperadas:
#   NODE_NAME        nome do serviço no compose (usado só em log)
#   BOOTNODE_HOST    hostname do bootnode no compose; vazio no próprio bootnode
#   BOOTNODE_PUBKEY  chave pública do bootnode, sem o prefixo 0x
#
set -euo pipefail

# O Besu recusa hostname em --p2p-host ("valid advertisement host required"):
# precisa ser o IP do container na rede do compose.
SELF_IP="$(getent hosts "$(hostname)" | awk '{print $1}' | head -1)"
echo "[${NODE_NAME:-besu}] IP p2p: ${SELF_IP}"

ARGS=(
  --data-path=/data
  --genesis-file=/config/genesis.json
  --node-private-key-file=/config/key
  --p2p-host="${SELF_IP}"
  --p2p-port=30303
  --rpc-http-enabled
  --rpc-http-host=0.0.0.0
  --rpc-http-port=8545
  --rpc-http-api=ETH,NET,WEB3,QBFT,ADMIN,TXPOOL,DEBUG
  --rpc-http-cors-origins=all
  --host-allowlist=*
  --min-gas-price=0
  --logging=INFO
)

# Nós não-bootnode esperam o bootnode aceitar conexões antes de subir, senão
# a descoberta falha e o nó fica isolado do consenso.
if [ -n "${BOOTNODE_HOST:-}" ]; then
  echo "[${NODE_NAME:-besu}] aguardando bootnode ${BOOTNODE_HOST}..."
  until curl -s -f -X POST -H 'Content-Type: application/json' \
      --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' \
      "http://${BOOTNODE_HOST}:8545" >/dev/null 2>&1; do
    sleep 2
  done
  BOOTNODE_IP="$(getent hosts "${BOOTNODE_HOST}" | awk '{print $1}' | head -1)"
  echo "[${NODE_NAME:-besu}] bootnode em ${BOOTNODE_IP}"
  ARGS+=(--bootnodes="enode://${BOOTNODE_PUBKEY}@${BOOTNODE_IP}:30303")
fi

exec besu "${ARGS[@]}"
