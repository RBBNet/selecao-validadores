# 2. Modelo de Dados e Interfaces

## 2.1 Contrato: `ValidatorSelectionIngress`

### Estado (Storage)
| Variável | Tipo | Visibilidade | Descrição | Histórias de Usuário (US) |
| :--- | :--- | :--- | :--- | :--- |
| `admins` | `IAdminProxy` | `public` | Endereço do AdminProxy (herdado de `Governable`). | [US1-2](../requisitos/02-ingress-selecao-validadores.md#us1-2), [US2-4](../requisitos/02-ingress-selecao-validadores.md#us2-4), [US5-5](../requisitos/02-ingress-selecao-validadores.md#us5-5), [US5-6](../requisitos/02-ingress-selecao-validadores.md#us5-6) |
| `validatorSelectionContract` | `address` | `public` | Endereço do contrato de lógica ativo. | [US1-2](../requisitos/02-ingress-selecao-validadores.md#us1-2), [US2-3](../requisitos/02-ingress-selecao-validadores.md#us2-3), [US2-4](../requisitos/02-ingress-selecao-validadores.md#us2-4), [US5-1](../requisitos/01-selecao-validadores.md#us5-1), [US5-3](../requisitos/02-ingress-selecao-validadores.md#us5-3), [US5-4](../requisitos/02-ingress-selecao-validadores.md#us5-4) |

## 2.2 Contrato: `ValidatorSelection`

### Estado (Storage)
| Variável | Tipo | Visibilidade | Descrição | Histórias de Usuário (US) |
| :--- | :--- | :--- | :--- | :--- |
| `accountsContract` | `IAccountRulesV2` | `public` | Contrato de regras de contas. | [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2), [US5-8](../requisitos/01-selecao-validadores.md#us5-8) |
| `nodesContract` | `INodeRulesV2` | `public` | Contrato de regras de nós. | [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2), [US5-9](../requisitos/01-selecao-validadores.md#us5-9) |
| `eligibleValidators` | `EnumerableSet.AddressSet` | `private` | Conjunto de validadores elegíveis. | [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US2-2](../requisitos/01-selecao-validadores.md#us2-2), [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-3](../requisitos/01-selecao-validadores.md#us4-3), [US4-4](../requisitos/01-selecao-validadores.md#us4-4) |
| `operationalValidators` | `EnumerableSet.AddressSet` | `private` | Conjunto de validadores operacionais ativos. | [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US2-1](../requisitos/01-selecao-validadores.md#us2-1), [US3-3](../requisitos/01-selecao-validadores.md#us3-3), [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2), [US4-3](../requisitos/01-selecao-validadores.md#us4-3), [US4-4](../requisitos/01-selecao-validadores.md#us4-4) |
| `protectedValidators` | `EnumerableSet.AddressSet` | `private` | Conjunto temporário de validadores protegidos contra remoção automática (inclui validadores recém-adicionados e operacionais após transições ou reconfigurações). | [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US3-1](../requisitos/01-selecao-validadores.md#us3-1), [US3-2](../requisitos/01-selecao-validadores.md#us3-2), [US3-3](../requisitos/01-selecao-validadores.md#us3-3), [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2), [US4-3](../requisitos/01-selecao-validadores.md#us4-3), [US4-4](../requisitos/01-selecao-validadores.md#us4-4) |
| `operationMode` | `OperationMode` | `public` | Modo atual (`Manual = 0`, `Automatic = 1`). | [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US3-1](../requisitos/01-selecao-validadores.md#us3-1) |
| `blocksBetweenSelection` | `uint256` | `public` | Intervalo entre seleções automáticas. | [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US3-2](../requisitos/01-selecao-validadores.md#us3-2) |
| `blocksWithoutProposeThreshold` | `uint256` | `public` | Limite de inatividade. | [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US3-2](../requisitos/01-selecao-validadores.md#us3-2), [US4-3](../requisitos/01-selecao-validadores.md#us4-3) |
| `nextSelectionBlock` | `uint256` | `public` | Bloco alvo para a próxima seleção. | [US3-1](../requisitos/01-selecao-validadores.md#us3-1), [US3-2](../requisitos/01-selecao-validadores.md#us3-2), [US3-3](../requisitos/01-selecao-validadores.md#us3-3) |
| `lastMonitoredBlock` | `uint256` | `public` | Bloco da última monitoração (anti-duplicidade). | [US3-1](../requisitos/01-selecao-validadores.md#us3-1), [US3-3](../requisitos/01-selecao-validadores.md#us3-3) |
| `lastBlockProposedBy` | `mapping(address => uint256)` | `public` | Último bloco proposto por validador. | [US3-1](../requisitos/01-selecao-validadores.md#us3-1), [US3-2](../requisitos/01-selecao-validadores.md#us3-2), [US3-3](../requisitos/01-selecao-validadores.md#us3-3), [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-3](../requisitos/01-selecao-validadores.md#us4-3), [US4-4](../requisitos/01-selecao-validadores.md#us4-4) |


## 2.3 Interface Comum, Eventos e Erros

```solidity
enum OperationMode { Manual, Automatic }

interface IValidatorList {
    function getValidators() external view returns (address[] memory);
}

interface IValidatorSelectionIngress is IValidatorList {
    function updateValidatorSelectionContract(address newContract) external;
    function updateAdminContract(address newAdmin) external;
    function removeValidatorSelectionContract() external;
    function removeAdminContract() external;
    function validatorSelectionContract() external view returns (address);
    function admins() external view returns (IAdminProxy);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IValidatorSelection is IValidatorList {
    function getEligibleValidators() external view returns (address[] memory);
    function setOperationMode(OperationMode mode) external;
    function executeMonitoring() external;
    function addEligibleValidator(address validator, bool alsoOperational) external;
    function removeEligibleValidator(address validator) external;
    function addEligibleValidator(bytes32 enodeHigh, bytes32 enodeLow, bool alsoOperational) external;
    function removeEligibleValidator(bytes32 enodeHigh, bytes32 enodeLow) external;
    function addOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow) external;
    function removeOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow) external;
    function addOperationalValidator(address validator) external;
    function removeOperationalValidator(address validator) external;
    function setSelectionParameters(uint256 blocksBetweenSelection, uint256 blocksWithoutProposeThreshold) external;
    function updateAdminContract(address newAdmin) external;
    function updateAccountsContract(address newAccountsContract) external;
    function updateNodesContract(address newNodesContract) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
```

Tanto o contrato `ValidatorSelection` quanto o `ValidatorSelectionIngress` devem implementar o padrão **ERC-165** (`supportsInterface`) para consulta e validação de interfaces. Ambos devem retornar `true` para seus respectivos identificadores de interface, assim como para o identificador da interface base `IValidatorList`.

### 2.3.1 Assinaturas de Eventos (Logs de Auditoria)
Para garantir a auditabilidade, rastreabilidade e indexação off-chain, os eventos com seus parâmetros indexados correspondentes devem ser emitidos conforme as tabelas abaixo:

#### No Contrato `ValidatorSelectionIngress`
| Evento | Parâmetros | Descrição | Histórias de Usuário (US) |
| :--- | :--- | :--- | :--- |
| `ValidatorSelectionContractUpdated` | `address indexed oldContract, address indexed newContract` | Emitido quando o contrato de lógica de seleção de validadores é atualizado. | [US5-1](../requisitos/01-selecao-validadores.md#us5-1), [US5-3](../requisitos/02-ingress-selecao-validadores.md#us5-3) |
| `AdminContractUpdated` | `address indexed oldAdmin, address indexed newAdmin` | Emitido quando o contrato de `Admins` é atualizado. | [US5-5](../requisitos/02-ingress-selecao-validadores.md#us5-5) |
| `ValidatorSelectionContractRemoved` | `address indexed oldContract` | Emitido quando o contrato de lógica é removido (emergência). | [US5-4](../requisitos/02-ingress-selecao-validadores.md#us5-4) |
| `AdminContractRemoved` | `address indexed oldAdmin` | Emitido quando o contrato de governança é removido (emergência). | [US5-6](../requisitos/02-ingress-selecao-validadores.md#us5-6) |

#### No Contrato `ValidatorSelection`
| Evento | Parâmetros | Descrição | Histórias de Usuário (US) |
| :--- | :--- | :--- | :--- |
| `OperationModeChanged` | `OperationMode indexed mode` | Emitido quando o modo de operação é alterado. | [US3-1](../requisitos/01-selecao-validadores.md#us3-1) |
| `MonitorExecuted` | `address indexed executor, uint256 indexed blockNumber` | Emitido quando o monitoramento de validadores é executado. | [US3-3](../requisitos/01-selecao-validadores.md#us3-3) |
| `SelectionExecuted` | `address[] operationalValidators` | Emitido após a execução de um ciclo de seleção. | [US3-3](../requisitos/01-selecao-validadores.md#us3-3) |
| `OperationalValidatorAdded` | `address indexed validator` | Emitido quando um validador operacional é adicionado. | [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-3](../requisitos/01-selecao-validadores.md#us4-3) |
| `OperationalValidatorRemoved` | `address indexed validator` | Emitido quando um validador operacional é removido automaticamente por inatividade. | [US3-3](../requisitos/01-selecao-validadores.md#us3-3) |
| `OperationalValidatorManuallyRemoved` | `address indexed validator` | Emitido quando um validador operacional é removido manualmente pela governança ou admin. | [US4-2](../requisitos/01-selecao-validadores.md#us4-2), [US4-4](../requisitos/01-selecao-validadores.md#us4-4) |
| `EligibleValidatorAdded` | `address indexed validator, bool indexed alsoOperational` | Emitido quando um validador elegível é adicionado (e opcionalmente definido como operacional). | [US4-3](../requisitos/01-selecao-validadores.md#us4-3) |
| `EligibleValidatorRemoved` | `address indexed validator` | Emitido quando um validador é removido do conjunto de elegíveis. | [US4-4](../requisitos/01-selecao-validadores.md#us4-4) |
| `SelectionParametersUpdated` | `uint256 blocksBetweenSelection, uint256 blocksWithoutProposeThreshold` | Emitido quando os parâmetros de seleção automática são atualizados. | [US3-2](../requisitos/01-selecao-validadores.md#us3-2), [US4-3](../requisitos/01-selecao-validadores.md#us4-3) |
| `AdminContractUpdated` | `address indexed oldAdmin, address indexed newAdmin` | Emitido quando o contrato de `Admins` (governança) é atualizado no contrato de Lógica. | [US5-7](../requisitos/01-selecao-validadores.md#us5-7) |
| `AccountsContractUpdated` | `address indexed oldAccounts, address indexed newAccounts` | Emitido quando o contrato de regras de contas é atualizado no contrato de Lógica. | [US5-8](../requisitos/01-selecao-validadores.md#us5-8) |
| `NodesContractUpdated` | `address indexed oldNodes, address indexed newNodes` | Emitido quando o contrato de regras de nós é atualizado no contrato de Lógica. | [US5-9](../requisitos/01-selecao-validadores.md#us5-9) |

### 2.3.2 Erros Customizados
Para economizar gás e fornecer mensagens de erro sem ambiguidade, os erros customizados devem ser utilizados conforme a tabela abaixo:

| Erro | Parâmetros | Origem / Declaração | Descrição / Caso de Uso | Histórias de Usuário (US) |
| :--- | :--- | :--- | :--- | :--- |
| `InvalidAddress()` | Nenhum | Local (`ValidatorSelection` / `ValidatorSelectionIngress`) | Endereço fornecido é igual a zero (`address(0)`). | [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US1-2](../requisitos/02-ingress-selecao-validadores.md#us1-2), [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2), [US4-3](../requisitos/01-selecao-validadores.md#us4-3), [US4-4](../requisitos/01-selecao-validadores.md#us4-4), [US5-1](../requisitos/01-selecao-validadores.md#us5-1), [US5-3](../requisitos/02-ingress-selecao-validadores.md#us5-3), [US5-5](../requisitos/02-ingress-selecao-validadores.md#us5-5) |
| `SameAddress(address current)` | `address current` | Local (`ValidatorSelection` / `ValidatorSelectionIngress`) | Tentativa de atualizar para o mesmo endereço que já está ativo. | [US5-1](../requisitos/01-selecao-validadores.md#us5-1), [US5-3](../requisitos/02-ingress-selecao-validadores.md#us5-3), [US5-5](../requisitos/02-ingress-selecao-validadores.md#us5-5) |
| `InvalidValidatorSelectionContract(address addr)` | `address addr` | Local (`ValidatorSelectionIngress`) | Contrato de lógica fornecido não retornou validadores válidos. | [US1-2](../requisitos/02-ingress-selecao-validadores.md#us1-2), [US5-1](../requisitos/01-selecao-validadores.md#us5-1), [US5-3](../requisitos/02-ingress-selecao-validadores.md#us5-3) |
| `InvalidAdminContract(address addr)` | `address addr` | Local (`ValidatorSelectionIngress` / `ValidatorSelection`) | Contrato admin proxy fornecido não implementou ou falhou na chamada de teste `isAuthorized(address(0))`. | [US1-2](../requisitos/02-ingress-selecao-validadores.md#us1-2), [US5-5](../requisitos/02-ingress-selecao-validadores.md#us5-5), [US5-7](../requisitos/01-selecao-validadores.md#us5-7) |
| `InvalidAccountsContract(address addr)` | `address addr` | Local (`ValidatorSelection`) | Contrato de regras de contas fornecido não implementou ou falhou na chamada de teste `isAccountActive(address(0))`. | [US5-8](../requisitos/01-selecao-validadores.md#us5-8) |
| `InvalidNodesContract(address addr)` | `address addr` | Local (`ValidatorSelection`) | Contrato de regras de nós fornecido não implementou ou falhou na chamada de teste `allowedNodes(0)`. | [US5-9](../requisitos/01-selecao-validadores.md#us5-9) |
| `DuplicateValidator(address validator)` | `address validator` | Local (`ValidatorSelection`) | Endereço de validador fornecido na lista inicial é duplicado. | [US1-1](../requisitos/01-selecao-validadores.md#us1-1) |
| `UnauthorizedAccess(address account)` | `address account` | Herdado (`Governable`) | A conta fornecida não possui a permissão necessária para executar a ação. | [US3-1](../requisitos/01-selecao-validadores.md#us3-1), [US3-2](../requisitos/01-selecao-validadores.md#us3-2), [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2), [US4-3](../requisitos/01-selecao-validadores.md#us4-3), [US4-4](../requisitos/01-selecao-validadores.md#us4-4), [US5-4](../requisitos/02-ingress-selecao-validadores.md#us5-4), [US5-6](../requisitos/02-ingress-selecao-validadores.md#us5-6) |
| `InactiveAccount(address account)` | `address account` | Local (`ValidatorSelection`) | A conta fornecida está inativa no contrato de regras de conta (`AccountRulesV2`). | [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2) |
| `NotLocalNode(bytes32 enodeHigh, bytes32 enodeLow)` | `bytes32 enodeHigh, bytes32 enodeLow` | Local (`ValidatorSelection`) | O enode/nó fornecido não pertence à mesma organização do administrador solicitante. | [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2) |
| `NotEligibleValidator(address validator)` | `address validator` | Local (`ValidatorSelection`) | O endereço fornecido não está presente no conjunto de validadores elegíveis. | [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-4](../requisitos/01-selecao-validadores.md#us4-4) |
| `AlreadyEligibleValidator(address validator)` | `address validator` | Local (`ValidatorSelection`) | O endereço fornecido já é um validador elegível. | [US4-3](../requisitos/01-selecao-validadores.md#us4-3) |
| `NotOperationalValidator(address validator)` | `address validator` | Local (`ValidatorSelection`) | O endereço fornecido não está presente no conjunto de validadores operacionais. | [US4-2](../requisitos/01-selecao-validadores.md#us4-2) |
| `AlreadyOperationalValidator(address validator)` | `address validator` | Local (`ValidatorSelection`) | O endereço fornecido já é um validador operacional. | [US4-1](../requisitos/01-selecao-validadores.md#us4-1) |
| `MinimumValidatorsReached()` | Nenhum | Local (`ValidatorSelection`) | Ação impedida porque reduziria o número de validadores operacionais abaixo do mínimo de segurança (1 para governança, 4 para administradores ou seleção automática). | [US4-2](../requisitos/01-selecao-validadores.md#us4-2), [US4-4](../requisitos/01-selecao-validadores.md#us4-4) |
| `InvalidBlocksBetweenSelection()` | Nenhum | Local (`ValidatorSelection`) | O parâmetro `blocksBetweenSelection` fornecido é menor que 1. | [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US3-2](../requisitos/01-selecao-validadores.md#us3-2) |
| `InvalidBlocksWithoutProposeThreshold()` | Nenhum | Local (`ValidatorSelection`) | O parâmetro `blocksWithoutProposeThreshold` fornecido é inválido (menor que a quantidade de validadores iniciais). | [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US3-2](../requisitos/01-selecao-validadores.md#us3-2) |
| `FewEligibleValidators()` | Nenhum | Local (`ValidatorSelection`) | Tentativa de inicializar o contrato com um número insuficiente de validadores (menor que 1). | [US1-1](../requisitos/01-selecao-validadores.md#us1-1) |
| `InvalidOperationMode()` | Nenhum | Local (`ValidatorSelection`) | O modo de operação informado não corresponde a nenhum valor válido do enum `OperationMode` (`Manual` ou `Automatic`). Embora o Solidity ≥0.8 reverta automaticamente ao decodificar valores inválidos de enum, este erro customizado garante diagnóstico explícito e testabilidade. | [US3-1](../requisitos/01-selecao-validadores.md#us3-1) |

*Nota sobre Herança de Erros: No Solidity, erros customizados são herdados pelo escopo de herança. O erro `UnauthorizedAccess` é declarado de forma única no contrato base `Governable` e, portanto, não deve ser redeclarado em `ValidatorSelection` ou `ValidatorSelectionIngress` para evitar erros de compilação por declarações duplicadas.*



## 2.4 Interfaces de Contratos Externos (Permissionamento RBB)

Para permitir a integração correta e o desenvolvimento sem ambiguidades, a seguir são apresentadas as assinaturas e tipos de dados correspondentes aos contratos externos de permissionamento utilizados:

### 2.4.1 `IAdminProxy`
Responsável pela verificação de autorizações de governança:
```solidity
interface IAdminProxy {
    function isAuthorized(address source) external view returns (bool);
}
```

### 2.4.2 `IAccountRulesV2`
Responsável pelo controle de acesso de contas e papéis administrativos:
```solidity
bytes32 constant GLOBAL_ADMIN_ROLE = keccak256("GLOBAL_ADMIN_ROLE");
bytes32 constant LOCAL_ADMIN_ROLE = keccak256("LOCAL_ADMIN_ROLE");

interface IAccountRulesV2 {
    struct AccountData {
        uint256 orgId;
        address account;
        bytes32 roleId;
        bytes32 dataHash;
        bool active;
    }
    function isAccountActive(address account) external view returns (bool);
    function getAccount(address account) external view returns (AccountData memory);
    function hasRole(bytes32 role, address account) external view returns (bool);
}
```

### 2.4.3 `INodeRulesV2`
Responsável pelo permissionamento e detalhamento de nós da rede:
```solidity
interface INodeRulesV2 {
    enum NodeType { Boot, Validator, Writer, WriterPartner, ObserverBoot, Observer, Other }
    function allowedNodes(uint256 nodeKey) external view returns (
        bytes32 enodeHigh,
        bytes32 enodeLow,
        NodeType nodeType,
        string memory name,
        uint256 orgId,
        bool active
    );
}
```

### 2.4.4 `Governable`

O contrato `Governable` é um contrato base abstrato herdado pelos contratos de seleção de validadores para prover controle de acesso com base nas permissões de administrador.

#### Estado (Storage)
| Variável | Tipo | Visibilidade | Descrição | Histórias de Usuário (US) |
| :--- | :--- | :--- | :--- | :--- |
| `admins` | `IAdminProxy` | `public` | Endereço do contrato de regras de administrador `AdminProxy`. | [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US1-2](../requisitos/02-ingress-selecao-validadores.md#us1-2), [US5-5](../requisitos/02-ingress-selecao-validadores.md#us5-5), [US5-6](../requisitos/02-ingress-selecao-validadores.md#us5-6), [US5-7](../requisitos/01-selecao-validadores.md#us5-7) |

#### Modificadores de Acesso
*   `onlyGovernance()`: Restringe a execução de funções para apenas contas autorizadas pelo contrato `AdminProxy` associado.

#### Erros Customizados
| Erro | Parâmetros | Descrição / Caso de Uso |
| :--- | :--- | :--- |
| `UnauthorizedAccess(address account)` | `address account` | A conta fornecida não possui a permissão necessária para executar a ação. |




