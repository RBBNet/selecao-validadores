# Scripts de Implantação e Configuração (Foundry)

Scripts em Solidity (Foundry) para automação do deploy e inicialização dos contratos `ValidatorSelection` e `ValidatorSelectionIngress` na Rede Blockchain Brasil (RBB).

## 1. Sequência de Implantação

A implantação ocorre obrigatoriamente em duas etapas devido às validações do construtor do `ValidatorSelectionIngress`, que exige que a lógica informada já esteja implantada e retorne ao menos 1 validador operacional:

```
Etapa 1: Deploy da Lógica
forge script script/Deploy.s.sol --rpc-url <RPC> --broadcast
├── Lê parâmetros e permissionamento de script/data/config.json
├── Instancia ValidatorSelection com a lista inicial de elegíveis
└── Retorna o endereço do ValidatorSelection

Configuração
└── Registrar o endereço do ValidatorSelection em script/data/config.json (.contracts.validatorSelection)

Etapa 2: Deploy do Ingress
forge script script/DeployIngress.s.sol --rpc-url <RPC> --broadcast
├── Lê .contracts.adminProxy e .contracts.validatorSelection de config.json
├── Valida compatibilidade de interface e presença do código EVM
├── Instancia ValidatorSelectionIngress
└── Retorna o endereço do Ingress a ser registrado no genesis.json do Besu
```

Para a visão geral do projeto e pré-requisitos, consulte [`README.md`](../README.md). Para a especificação dos contratos Solidity, consulte [`src/README.md`](../src/README.md).

## 2. Estrutura do Diretório

```
script/
├── Deploy.s.sol                   # Script de deploy do ValidatorSelection
├── DeployIngress.s.sol            # Script de deploy do ValidatorSelectionIngress
└── data/                          # Dados de inicialização
    ├── config.json                # Parâmetros de deploy e endereços de permissionamento
    └── genesis-transition.example.json # Exemplo de transição QBFT para genesis.json
```

## 3. Arquivos de Configuração (`script/data/`)

### 3.1 `script/data/config.json`

Parâmetros de entrada lidos pelos scripts via `stdJson`:

| Campo | Tipo | Descrição |
|---|---|---|
| `contracts.adminProxy` | `address` | Endereço do `AdminProxy` (governança da RBB). |
| `contracts.accountRules` | `address` | Endereço do `AccountRulesV2` (regras de contas permitidas). |
| `contracts.nodeRules` | `address` | Endereço do `NodeRulesV2` (regras de nós/enodes permitidos). |
| `contracts.validatorSelection` | `string` | Endereço do `ValidatorSelection` implantado na Etapa 1. Preenchido antes da Etapa 2. |
| `initialNextSelectionBlock` | `uint256` | Bloco futuro inicial para disparo da seleção automática. |
| `initialBlocksBetweenSelection` | `uint256` | Intervalo de blocos entre ciclos (`blocksBetweenSelection`). |
| `initialBlocksWithoutProposeThreshold` | `uint256` | Limite de blocos inativos tolerados (`blocksWithoutProposeThreshold`). |
| `initialEligibleValidators` | `address[]` | Lista inicial de validadores elegíveis e operacionais. |

### 3.2 `script/data/genesis-transition.example.json`

Modelo da transição QBFT para inclusão na chave `config.transitions.qbft` do `genesis.json` dos nós Besu da rede:

```json
{
  "transitions": {
    "qbft": [
      {
        "block": 1000000,
        "validatorselectionmode": "contract",
        "validatorcontractaddress": "<ENDERECO_DO_VALIDATOR_SELECTION_INGRESS>"
      }
    ]
  }
}
```

## 4. Pré-requisitos e Preparação

Confirme a instalação do Foundry (`forge`, `cast`) e configure o arquivo `.env` na raiz do repositório conforme [`.env.example`](../.env.example):

```bash
PRIVATE_KEY=0x...
RPC_URL=http://localhost:8545
```

A conta correspondente à `PRIVATE_KEY` deve possuir saldo para custear o envio das transações de implantação.

## 5. Instruções de Execução

### 5.1 Etapa 1: Deploy do `ValidatorSelection`

Simulação (*dry-run*):
```bash
forge script script/Deploy.s.sol --rpc-url $RPC_URL
```

Execução e envio de transações (*broadcast*):
```bash
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast --legacy
```

O script exibirá no terminal:
```text
ValidatorSelection deployed at: 0x...
```

Copie o endereço gerado e informe no campo `.contracts.validatorSelection` do arquivo [`script/data/config.json`](data/config.json).

### 5.2 Etapa 2: Deploy do `ValidatorSelectionIngress`

Simulação (*dry-run*):
```bash
forge script script/DeployIngress.s.sol --rpc-url $RPC_URL
```

Execução e envio de transações (*broadcast*):
```bash
forge script script/DeployIngress.s.sol --rpc-url $RPC_URL --broadcast --legacy
```

O script exibirá no terminal:
```text
ValidatorSelectionIngress deployed at: 0x...
Use este endereco em validatorcontractaddress na transicao QBFT do genesis.
```

## 6. Verificação Pós-Implantação

Para validar a configuração dos contratos implantados via `cast`:

```bash
# Consultar o contrato de lógica registrado no Ingress
cast call <ENDERECO_INGRESS> "getValidatorSelectionContract()(address)" --rpc-url $RPC_URL

# Consultar a lista de validadores operacionais retornada pelo Ingress
cast call <ENDERECO_INGRESS> "getValidators()(address[])" --rpc-url $RPC_URL

# Consultar validadores ativos no consenso Besu (após o bloco da transição)
cast rpc qbft_getValidatorsByBlockNumber '"latest"' --rpc-url $RPC_URL
```

O endereço retornado pelo deploy do `ValidatorSelectionIngress` deve ser compartilhado com os operadores da rede para inclusão na transição de gênesis.
