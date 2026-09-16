#!/usr/bin/env bash
#
# Gera o genesis QBFT, as chaves dos 6 nós e o .env consumido pelo compose.
# Idempotente: apaga e regenera tudo.
#
set -euo pipefail

cd "$(dirname "$0")"

BESU_IMAGE="${BESU_IMAGE:-hyperledger/besu:26.7.1}"

echo "== Gerando genesis QBFT e chaves dos nós =="
rm -rf networkFiles nodes
docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/w" -w /w "$BESU_IMAGE" \
  operator generate-blockchain-config \
  --config-file=qbft-config.json \
  --to=networkFiles \
  --private-key-file-name=key >/dev/null

# As chaves saem em networkFiles/keys/<endereço>/. O compose espera nodes/nodeN/key,
# então distribuímos em ordem alfabética de endereço para tornar o mapeamento estável.
mkdir -p nodes
i=0
VALIDATORS=()
for dir in $(find networkFiles/keys -mindepth 1 -maxdepth 1 -type d | sort); do
  mkdir -p "nodes/node${i}"
  cp "${dir}/key" "nodes/node${i}/key"
  cp "${dir}/key.pub" "nodes/node${i}/key.pub"
  VALIDATORS+=("$(basename "$dir")")
  echo "  node${i} -> $(basename "$dir")"
  i=$((i + 1))
done

# O enode do bootnode é a chave pública do node0 sem o prefixo 0x.
BOOTNODE_PUBKEY="$(sed 's/^0x//' nodes/node0/key.pub)"

{
  echo "BOOTNODE_PUBKEY=${BOOTNODE_PUBKEY}"
  echo "E2E_VALIDATORS=$(IFS=,; echo "${VALIDATORS[*]}")"
} > .env

echo "== .env gerado =="
cat .env
