# 3. Especificação Detalhada das Funções

## 3.1 ValidatorSelectionIngress

### 3.1.1 `constructor`
**Assinatura:** `constructor(address _adminProxy, address _validatorSelectionContract)`
*   **Histórias de Usuário Associadas:** [US1-2](../requisitos/02-ingress-selecao-validadores.md#us1-2)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `_adminProxy` | `address` | Endereço do contrato de governança AdminProxy. |
| `_validatorSelectionContract` | `address` | Endereço do contrato de lógica de seleção de validadores. |

*   **Validações:**
    *   `_adminProxy != address(0)` e `_validatorSelectionContract != address(0)` (se não, reverte com `InvalidAddress()`).
    *   `_adminProxy.isAuthorized(address(0))` via `try/catch` (se falhar, reverte com `InvalidAdminContract`).
    *   `_validatorSelectionContract.getValidators()` via `try/catch` (se falhar ou retornar lista vazia, reverte com `InvalidValidatorSelectionContract`).
*   **Efeitos:** Inicializa `admins` e `validatorSelectionContract`.

### 3.1.2 `getValidators`
**Assinatura:** `function getValidators() external view returns (address[] memory)`
*   **Histórias de Usuário Associadas:** [US2-3](../requisitos/02-ingress-selecao-validadores.md#us2-3)

*   **Parâmetros:** Nenhum.
*   **Retorno:** `address[] memory` (Lista de endereços de validadores operacionais ativos).
*   **Validações:** Nenhuma.
*   **Algoritmo de Execução:**
    1. Se `validatorSelectionContract == address(0)`:
        * Retorna uma lista de tamanho 1 contendo o endereço `block.coinbase`.
    2. Caso contrário:
        * Tenta realizar uma chamada externa para a função `getValidators()` do contrato `validatorSelectionContract` dentro de um bloco `try/catch`.
        * Se a chamada retornar com sucesso e o tamanho da lista de validadores for maior ou igual a 1 (`length >= 1`):
            * Retorna a lista recebida.
        * Se a chamada falhar (reverter) ou se retornar uma lista de tamanho zero:
            * Retorna uma lista de tamanho 1 contendo o endereço `block.coinbase`.

### 3.1.3 `updateValidatorSelectionContract`
**Assinatura:** `function updateValidatorSelectionContract(address _newContract) external`
*   **Histórias de Usuário Associadas:** [US5-1](../requisitos/01-selecao-validadores.md#us5-1), [US5-3](../requisitos/02-ingress-selecao-validadores.md#us5-3)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `_newContract` | `address` | Endereço do novo contrato de lógica de seleção de validadores. |

*   **Acesso:** `onlyGovernance`
*   **Validações:**
    *   `_newContract != address(0)` (reverte com `InvalidAddress()`).
    *   `_newContract != validatorSelectionContract` (reverte com `SameAddress()`).
    *   `_newContract.getValidators()` deve responder com `length >= 1` (se falhar ou retornar lista vazia, reverte com `InvalidValidatorSelectionContract`).
*   **Efeitos:** Atualiza `validatorSelectionContract` e emite `ValidatorSelectionContractUpdated(old, new)`.

### 3.1.4 `updateAdminContract`
**Assinatura:** `function updateAdminContract(address _newAdmin) external`
*   **Histórias de Usuário Associadas:** [US5-5](../requisitos/02-ingress-selecao-validadores.md#us5-5)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `_newAdmin` | `address` | Endereço do novo contrato AdminProxy. |

*   **Acesso:** `onlyGovernance`
*   **Validações:**
    *   `_newAdmin != address(0)` (prevenção de órfão de governança, reverte com `InvalidAddress()`).
    *   `_newAdmin != address(admins)` (reverte com `SameAddress()`).
    *   `_newAdmin` deve implementar `isAuthorized()` (se falhar na chamada externa, reverte com `InvalidAdminContract`).
*   **Efeitos:** Atualiza `admins` e emite `AdminContractUpdated(old, new)`.

### 3.1.5 `removeValidatorSelectionContract`
**Assinatura:** `function removeValidatorSelectionContract() external`
*   **Histórias de Usuário Associadas:** [US5-4](../requisitos/02-ingress-selecao-validadores.md#us5-4)

*   **Parâmetros:** Nenhum.
*   **Acesso:** `onlyGovernance`
*   **Efeitos:** Define `validatorSelectionContract` como `address(0)` (operações de emergência). Emite `ValidatorSelectionContractRemoved(oldContract)`.

### 3.1.6 `removeAdminContract`
**Assinatura:** `function removeAdminContract() external`
*   **Histórias de Usuário Associadas:** [US5-6](../requisitos/02-ingress-selecao-validadores.md#us5-6)

*   **Parâmetros:** Nenhum.
*   **Acesso:** `onlyGovernance`
*   **Efeitos:** Define `admins` como `IAdminProxy(address(0))` (operações de emergência). Emite `AdminContractRemoved(oldAdmin)`.

### 3.1.7 `supportsInterface`
**Assinatura:** `function supportsInterface(bytes4 interfaceId) external view returns (bool)`
*   **Histórias de Usuário Associadas:** [US5-2](../requisitos/01-selecao-validadores.md#us5-2)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `interfaceId` | `bytes4` | Identificador da interface de acordo com o padrão ERC-165. |

*   **Retorno:** `bool` (`true` se a interface for suportada, `false` caso contrário).
*   **Efeitos:** Retorna `true` se `interfaceId` corresponder ao ERC-165 (`0x01ffc9a7`) ou à interface do contrato Ingress (`IValidatorSelectionIngress`).

### 3.1.8 `validatorSelectionContract` e `admins` (Consultas Diretas)
**Assinatura:**
- `function validatorSelectionContract() external view returns (address)`
- `function admins() external view returns (IAdminProxy)`
*   **Histórias de Usuário Associadas:** [US2-4](../requisitos/02-ingress-selecao-validadores.md#us2-4)

*   **Parâmetros:** Nenhum.
*   **Retorno:** `validatorSelectionContract` retorna `address`; `admins` retorna `IAdminProxy` (endereço tipado do contrato AdminProxy associado no Ingress).
*   **Acesso:** Livre.

---

## 3.2 ValidatorSelection

### 3.2.1 `constructor`
**Assinatura:** `constructor(address _adminProxy, address _accountsContract, address _nodesContract, address[] memory _initialValidators, uint256 _blocksBetweenSelection, uint256 _blocksWithoutProposeThreshold)`
*   **Histórias de Usuário Associadas:** [US1-1](../requisitos/01-selecao-validadores.md#us1-1)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `_adminProxy` | `address` | Endereço do contrato de governança AdminProxy. |
| `_accountsContract` | `address` | Endereço do contrato de regras de contas (`IAccountRulesV2`). |
| `_nodesContract` | `address` | Endereço do contrato de regras de nós (`INodeRulesV2`). |
| `_initialValidators` | `address[]` | Lista de endereços dos validadores iniciais. |
| `_blocksBetweenSelection` | `uint256` | Intervalo em blocos entre seleções automáticas. |
| `_blocksWithoutProposeThreshold` | `uint256` | Limite em blocos de inatividade permitida para um validador. |

*   **Validações:**
    *   Contratos externos (`_adminProxy`, `_accountsContract`, `_nodesContract`) != `address(0)` (caso contrário, reverte com `InvalidAddress()`).
    *   `_initialValidators.length >= 1` (caso contrário, reverte com `FewEligibleValidators()`).
    *   Cada validador em `_initialValidators` deve ser diferente de `address(0)` (caso contrário, reverte com `InvalidAddress()`).
    *   `_blocksBetweenSelection >= 1` (caso contrário, reverte com `InvalidBlocksBetweenSelection()`).
    *   `_blocksWithoutProposeThreshold >= _initialValidators.length` (caso contrário, reverte com `InvalidBlocksWithoutProposeThreshold()`).
*   **Efeitos:**
    *   Popula `eligibleValidators`, `operationalValidators` e `protectedValidators` com `_initialValidators`.
    *   Inicializa os parâmetros `blocksBetweenSelection` e `blocksWithoutProposeThreshold`.
    *   Define `operationMode = Manual`.

### 3.2.2 `setOperationMode`
**Assinatura:** `function setOperationMode(OperationMode _mode) external`
*   **Histórias de Usuário Associadas:** [US3-1](../requisitos/01-selecao-validadores.md#us3-1)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `_mode` | `OperationMode` | Novo modo de operação (`Manual = 0`, `Automatic = 1`). |

*   **Acesso:** `onlyGovernance`
*   **Validações:**
    *   O valor de `_mode` deve ser um valor válido do enum `OperationMode` (`Manual` ou `Automatic`). Caso contrário, reverte com `InvalidOperationMode()`.
*   **Regras de Transição (para o Modo Automatic):**
    *   Se transicionando para `Automatic` (i.e., `_mode == Automatic`):
        1. Popula o conjunto temporário de validadores protegidos (`protectedValidators`) com todos os elementos de `operationalValidators`.
        2. Define `nextSelectionBlock = block.number + blocksBetweenSelection`.
        3. Define `lastMonitoredBlock = 0`.
*   **Efeitos:** Altera `operationMode` e emite `OperationModeChanged(_mode)`.

### 3.2.3 `executeMonitoring`
**Assinatura:** `function executeMonitoring() external`
*   **Histórias de Usuário Associadas:** [US3-3](../requisitos/01-selecao-validadores.md#us3-3)

*   **Parâmetros:** Nenhum.
*   **Acesso:** Livre (qualquer conta ou Monitor off-chain).
*   **Algoritmo de Execução:**
    1. Emite `MonitorExecuted(msg.sender, block.number)`. *(Nota: este evento é emitido incondicionalmente para toda chamada, independentemente do modo de operação ou do estado de anti-duplicidade. Essa decisão é intencional para fins de auditoria e transparência (OLA), conforme definido na US3-3, critério 5.2 e dúvida 5.)*
    2. Se `operationMode != Automatic` ou `lastMonitoredBlock == block.number` (anti-duplicidade), encerra a execução (retorna com sucesso).
    3. Atualiza `lastMonitoredBlock = block.number`.
    4. Registra a proposição: `lastBlockProposedBy[block.coinbase] = block.number`.
    5. Se `block.number >= nextSelectionBlock` (Ciclo de Seleção Automática) *(Nota: a condição utiliza `>=` ao invés de `==` por resiliência — garante que o ciclo de seleção seja executado mesmo que nenhuma transação de monitoração tenha sido processada exatamente no bloco alvo, cobrindo cenários de blocos sem monitoração.)*:
        *   **Fase 1: Identificação de inativos.** Para cada validador `V` em `operationalValidators`, se `(block.number - lastBlockProposedBy[V]) > blocksWithoutProposeThreshold`, marca `V` para remoção.
        *   **Fase 2: Filtro e Remoção.** Para cada marcado para remoção:
            *   Se `protectedValidators.contains(V)` (protegido), ignora a remoção.
            *   Se `operationalValidators.length - 1 >= 4` (garantindo que restarão pelo menos `4` operacionais ativos após a remoção), remove `V` de `operationalValidators` e emite `OperationalValidatorRemoved(V)`.
            *   Se violar o mínimo de 4 operacionais, ignora a remoção de `V`.
        *   **Fase 3: Reset de Ciclo.**
            *   Limpa o conjunto temporário de validadores protegidos (`protectedValidators`) conforme as regras de esvaziamento do conjunto de proteção.
            *   Define `nextSelectionBlock = block.number + blocksBetweenSelection`.
            *   Emite `SelectionExecuted(operationalValidators.values())`.

### 3.2.4 `addOperationalValidator (via Enode)`
**Assinatura:** `function addOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow) external`
*   **Histórias de Usuário Associadas:** [US4-1](../requisitos/01-selecao-validadores.md#us4-1)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `enodeHigh` | `bytes32` | Primeiros 32 bytes do enode do validador. |
| `enodeLow` | `bytes32` | Últimos 32 bytes do enode do validador. |

*   **Acesso:** Admin Ativo da própria organização (Global ou Local).
*   **Validações:**
    *   Garante que a conta chamadora seja um administrador (Global ou Local) ativo, conforme as regras de verificação de administrador.
    *   Garante que o validador pertença à mesma organização do administrador solicitante, conforme as regras de vínculo organizacional.
    *   O endereço `V` do validador (obtido por meio da derivação do hash dos parâmetros `enodeHigh` e `enodeLow` do enode) deve estar em `eligibleValidators` (reverte com `NotEligibleValidator()`) e NÃO em `operationalValidators` (reverte com `AlreadyOperationalValidator()`).
*   **Efeitos:** Adiciona `V` a `operationalValidators` e a `protectedValidators`. Emite `OperationalValidatorAdded(V)`.

### 3.2.5 `addOperationalValidator (via Endereço)`
**Assinatura:** `function addOperationalValidator(address validator) external`
*   **Histórias de Usuário Associadas:** [US4-1](../requisitos/01-selecao-validadores.md#us4-1)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `validator` | `address` | Endereço do validador a ser ativado como operacional. |

*   **Acesso:** `onlyGovernance`
*   **Validações:**
    *   `validator != address(0)` (reverte com `InvalidAddress()`).
    *   `validator` deve estar em `eligibleValidators` (reverte com `NotEligibleValidator()`) e NÃO em `operationalValidators` (reverte com `AlreadyOperationalValidator()`).
*   **Efeitos:** Adiciona `validator` a `operationalValidators` e a `protectedValidators`. Emite `OperationalValidatorAdded(validator)`.

### 3.2.6 `removeOperationalValidator (via Enode)`
**Assinatura:** `function removeOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow) external`
*   **Histórias de Usuário Associadas:** [US4-2](../requisitos/01-selecao-validadores.md#us4-2)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `enodeHigh` | `bytes32` | Primeiros 32 bytes do enode do validador. |
| `enodeLow` | `bytes32` | Últimos 32 bytes do enode do validador. |

*   **Acesso:** Admin Ativo da própria organização (Global ou Local).
*   **Validações:**
    *   Garante que a conta chamadora seja um administrador (Global ou Local) ativo, conforme as regras de verificação de administrador.
    *   Garante que o validador pertença à mesma organização do administrador solicitante, conforme as regras de vínculo organizacional.
    *   O endereço `V` do validador (obtido por meio da derivação do hash dos parâmetros `enodeHigh` e `enodeLow` do enode) deve estar em `operationalValidators` (reverte com `NotOperationalValidator()`).
    *   **Invariante:** `operationalValidators.length - 1 >= 4` (reverte com `MinimumValidatorsReached()` se a remoção reduzir o conjunto de operacionais abaixo de 4). Esta invariante é mais restritiva para administradores conforme a regra 4.5 da US4-2.
*   **Efeitos:** Remove `V` de `operationalValidators` e de `protectedValidators` (se presente). O validador continua em `eligibleValidators`. Emite `OperationalValidatorManuallyRemoved(V)`.

### 3.2.7 `removeOperationalValidator (via Endereço)`
**Assinatura:** `function removeOperationalValidator(address validator) external`
*   **Histórias de Usuário Associadas:** [US4-2](../requisitos/01-selecao-validadores.md#us4-2)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `validator` | `address` | Endereço do validador a ser removido de operacional. |

*   **Acesso:** `onlyGovernance`
*   **Validações:**
    *   `validator != address(0)` (reverte com `InvalidAddress()`).
    *   `validator` deve estar em `operationalValidators` (reverte com `NotOperationalValidator()`).
    *   **Invariante:** `operationalValidators.length - 1 >= 1` (reverte com `MinimumValidatorsReached()`). Esta invariante é menos restritiva para a governança conforme a regra 4.5 da US4-2.
*   **Efeitos:** Remove `validator` de `operationalValidators` e de `protectedValidators` (se presente). O validador continua em `eligibleValidators`. Emite `OperationalValidatorManuallyRemoved(validator)`.

### 3.2.8 `addEligibleValidator (via Endereço)`
**Assinatura:** `function addEligibleValidator(address _validator, bool _alsoOperational) external`
*   **Histórias de Usuário Associadas:** [US4-3](../requisitos/01-selecao-validadores.md#us4-3)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `_validator` | `address` | Endereço do novo validador elegível. |
| `_alsoOperational` | `bool` | Indica se o validador deve ser ativado diretamente no conjunto operacional. |

*   **Acesso:** `onlyGovernance`
*   **Validações:** `_validator != address(0)` (reverte com `InvalidAddress()`) e NÃO estar em `eligibleValidators` (reverte com `AlreadyEligibleValidator()`).
*   **Efeitos:**
    *   Adiciona `_validator` a `eligibleValidators`. Emite `EligibleValidatorAdded(_validator, _alsoOperational)`.
    *   Se `_alsoOperational == true`, insere em `operationalValidators` e `protectedValidators`. Emite `OperationalValidatorAdded(_validator)` para garantir consistência de auditoria com a US4-1.
    *   **Ajuste de Parâmetro Automático:** Se `blocksWithoutProposeThreshold < eligibleValidators.length()`, define `blocksWithoutProposeThreshold = eligibleValidators.length()` e emite `SelectionParametersUpdated`.

### 3.2.9 `addEligibleValidator (via Enode)`
**Assinatura:** `function addEligibleValidator(bytes32 _enodeHigh, bytes32 _enodeLow, bool _alsoOperational) external`
*   **Histórias de Usuário Associadas:** [US4-3](../requisitos/01-selecao-validadores.md#us4-3)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `_enodeHigh` | `bytes32` | Primeiros 32 bytes do enode do validador. |
| `_enodeLow` | `bytes32` | Últimos 32 bytes do enode do validador. |
| `_alsoOperational` | `bool` | Indica se o validador deve ser ativado diretamente no conjunto operacional. |

*   **Acesso:** `onlyGovernance`
*   **Validações:**
    *   Deriva o endereço `V` do validador a partir de `_enodeHigh` e `_enodeLow`.
    *   `V != address(0)` (reverte com `InvalidAddress()`) e NÃO estar em `eligibleValidators` (reverte com `AlreadyEligibleValidator()`).
*   **Efeitos:**
    *   Adiciona `V` a `eligibleValidators`. Emite `EligibleValidatorAdded(V, _alsoOperational)`.
    *   Se `_alsoOperational == true`, insere em `operationalValidators` e `protectedValidators`. Emite `OperationalValidatorAdded(V)`.
    *   **Ajuste de Parâmetro Automático:** Se `blocksWithoutProposeThreshold < eligibleValidators.length()`, define `blocksWithoutProposeThreshold = eligibleValidators.length()` e emite `SelectionParametersUpdated`.

### 3.2.10 `removeEligibleValidator (via Endereço)`
**Assinatura:** `function removeEligibleValidator(address _validator) external`
*   **Histórias de Usuário Associadas:** [US4-4](../requisitos/01-selecao-validadores.md#us4-4)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `_validator` | `address` | Endereço do validador a ser removido da elegibilidade. |

*   **Acesso:** `onlyGovernance`
*   **Validações:**
    *   `_validator != address(0)` (reverte com `InvalidAddress()`).
    *   `_validator` deve estar em `eligibleValidators` (reverte com `NotEligibleValidator()`).
    *   Se estiver em `operationalValidators`, a remoção não pode reduzir o conjunto a zero (`operationalValidators.length - 1 >= 1`, reverte com `MinimumValidatorsReached()`).
*   **Efeitos:**
    *   Se `_validator` estiver no conjunto `operationalValidators`, emite `OperationalValidatorManuallyRemoved(_validator)`.
    *   Remove de `eligibleValidators`, `operationalValidators` e `protectedValidators`.
    *   Emite `EligibleValidatorRemoved(_validator)`.

### 3.2.11 `removeEligibleValidator (via Enode)`
**Assinatura:** `function removeEligibleValidator(bytes32 _enodeHigh, bytes32 _enodeLow) external`
*   **Histórias de Usuário Associadas:** [US4-4](../requisitos/01-selecao-validadores.md#us4-4)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `_enodeHigh` | `bytes32` | Primeiros 32 bytes do enode do validador. |
| `_enodeLow` | `bytes32` | Últimos 32 bytes do enode do validador. |

*   **Acesso:** `onlyGovernance`
*   **Validações:**
    *   Deriva o endereço `V` do validador a partir de `_enodeHigh` e `_enodeLow`.
    *   `V != address(0)` (reverte com `InvalidAddress()`).
    *   `V` deve estar em `eligibleValidators` (reverte com `NotEligibleValidator()`).
    *   Se estiver em `operationalValidators`, a remoção não pode reduzir o conjunto a zero (`operationalValidators.length - 1 >= 1`, reverte com `MinimumValidatorsReached()`).
*   **Efeitos:**
    *   Se `V` estiver no conjunto `operationalValidators`, emite `OperationalValidatorManuallyRemoved(V)`.
    *   Remove de `eligibleValidators`, `operationalValidators` e `protectedValidators`.
    *   Emite `EligibleValidatorRemoved(V)`.

### 3.2.12 `setSelectionParameters`
**Assinatura:** `function setSelectionParameters(uint256 _blocksBetweenSelection, uint256 _blocksWithoutProposeThreshold) external`
*   **Histórias de Usuário Associadas:** [US3-2](../requisitos/01-selecao-validadores.md#us3-2)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `_blocksBetweenSelection` | `uint256` | Novo intervalo em blocos entre as seleções. |
| `_blocksWithoutProposeThreshold` | `uint256` | Novo limite máximo em blocos de inatividade. |

*   **Acesso:** `onlyGovernance`
*   **Validações:** `_blocksBetweenSelection >= 1` (reverte com `InvalidBlocksBetweenSelection()`) e `_blocksWithoutProposeThreshold >= eligibleValidators.length()` (reverte com `InvalidBlocksWithoutProposeThreshold()`).
*   **Efeitos:**
    *   Atualiza as variáveis correspondentes.
    *   Popula o conjunto temporário de validadores protegidos (`protectedValidators`) com todos os elementos de `operationalValidators`.
    *   Define `nextSelectionBlock = block.number + _blocksBetweenSelection`.
    *   Emite `SelectionParametersUpdated`.

### 3.2.13 `getEligibleValidators`
**Assinatura:** `function getEligibleValidators() external view returns (address[] memory)`
*   **Histórias de Usuário Associadas:** [US2-2](../requisitos/01-selecao-validadores.md#us2-2)

*   **Parâmetros:** Nenhum.
*   **Retorno:** `address[] memory` (Lista contendo todos os endereços do conjunto `eligibleValidators`).
*   **Acesso:** Livre (qualquer conta).

### 3.2.14 `getValidators`
**Assinatura:** `function getValidators() external view returns (address[] memory)`
*   **Histórias de Usuário Associadas:** [US2-1](../requisitos/01-selecao-validadores.md#us2-1)

*   **Parâmetros:** Nenhum.
*   **Retorno:** `address[] memory` (Lista contendo todos os endereços do conjunto `operationalValidators`).
*   **Acesso:** Livre (qualquer conta ou o Besu).

### 3.2.15 `supportsInterface`
**Assinatura:** `function supportsInterface(bytes4 interfaceId) external view returns (bool)`
*   **Histórias de Usuário Associadas:** [US5-2](../requisitos/01-selecao-validadores.md#us5-2)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `interfaceId` | `bytes4` | Identificador da interface de acordo com o padrão ERC-165. |

*   **Retorno:** `bool` (`true` se a interface for suportada, `false` caso contrário).
*   **Efeitos:** Retorna `true` se `interfaceId` corresponder ao ERC-165 (`0x01ffc9a7`) ou à interface do contrato de lógica (`IValidatorSelection`).

### 3.2.16 Regras Internas de Validação e Processamento

As seguintes diretrizes descrevem as validações internas, critérios de acesso e o processamento de dados necessários para garantir a integridade das operações e o controle organizacional:

#### Verificação de Administrador Ativo
*   **Histórias de Usuário Associadas:** [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2)

Para certas operações restritas a administradores locais ou globais (como a ativação ou remoção de validadores de suas próprias organizações), o contrato deve validar se a conta chamadora:
1. Possui o papel `GLOBAL_ADMIN_ROLE` ou `LOCAL_ADMIN_ROLE` atribuído no contrato de contas (`IAccountRulesV2`). Caso contrário, a execução é interrompida com o erro `UnauthorizedAccess`.
2. Está com seu status marcado como ativo no contrato de contas. Caso contrário, a execução é interrompida com o erro `InactiveAccount`.

#### Validação de Vínculo Organizacional
*   **Histórias de Usuário Associadas:** [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2)

Para garantir a autonomia e o isolamento entre organizações participantes, um administrador só pode interagir com nós validadores vinculados à sua própria organização. A validação obedece às seguintes regras:
1. Identifica-se a organização (`orgId`) associada à conta do administrador no contrato de contas (`IAccountRulesV2`).
2. Identifica-se a organização (`orgId`) associada ao nó validador no contrato de regras de nós (`INodeRulesV2`), consultando-o por meio de sua chave de identificação do nó.
3. Se os identificadores de organização não forem idênticos, a execução é interrompida com o erro `NotLocalNode`.

#### Derivação da Chave Única do Nó
*   **Histórias de Usuário Associadas:** [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2)

A chave única de um nó Besu é computada a partir de sua chave pública (representada por duas partes de 32 bytes: `enodeHigh` e `enodeLow`). O identificador numérico correspondente é o resultado do hash `keccak256` dessas duas partes concatenadas (`abi.encodePacked`), convertido para um inteiro sem sinal de 256 bits (`uint256`).

#### Derivação do Endereço do Validador (Nó)
*   **Histórias de Usuário Associadas:** [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2)

O endereço (`address`) de um validador/nó é derivado a partir de sua chave pública de 64 bytes (representada pelas duas partes de 32 bytes: `enodeHigh` e `enodeLow`). O endereço corresponde aos 20 bytes menos significativos do hash `keccak256` dessas duas partes concatenadas (`abi.encodePacked`).

A expressão em Solidity para esta derivação é:
`address(uint160(uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))))`

#### Esvaziamento do Conjunto de Proteção
*   **Histórias de Usuário Associadas:** [US3-1](../requisitos/01-selecao-validadores.md#us3-1), [US3-2](../requisitos/01-selecao-validadores.md#us3-2), [US3-3](../requisitos/01-selecao-validadores.md#us3-3), [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2), [US4-3](../requisitos/01-selecao-validadores.md#us4-3), [US4-4](../requisitos/01-selecao-validadores.md#us4-4)

Para limpar o conjunto temporário de validadores protegidos (`protectedValidators`) diante da ausência de uma função `.clear()` na biblioteca padrão `EnumerableSet` da OpenZeppelin, a remoção deve ser realizada de forma iterativa (por exemplo, obtendo e removendo repetidamente o último elemento do conjunto) até que a quantidade total de elementos seja zero.

### 3.2.17 `updateAdminContract`
**Assinatura:** `function updateAdminContract(address _newAdmin) external`
*   **Histórias de Usuário Associadas:** [US5-7](../requisitos/01-selecao-validadores.md#us5-7)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `_newAdmin` | `address` | Endereço do novo contrato AdminProxy. |

*   **Acesso:** `onlyGovernance`
*   **Validações:**
    *   `_newAdmin != address(0)` (reverte com `InvalidAddress()`).
    *   `_newAdmin != address(admins)` (reverte com `SameAddress()`).
    *   `_newAdmin` deve responder com sucesso à chamada externa `isAuthorized(address(0))` realizada dentro de um bloco `try/catch`. Caso falhe ou reverta, a execução é interrompida revertendo com `InvalidAdminContract(_newAdmin)`.
*   **Efeitos:**
    *   Atualiza o endereço do contrato `admins` (ponteiro de governança) com `_newAdmin`.
    *   Emite o evento `AdminContractUpdated(address indexed oldAdmin, address indexed newAdmin)`.

### 3.2.18 `updateAccountsContract`
**Assinatura:** `function updateAccountsContract(address _newAccountsContract) external`
*   **Histórias de Usuário Associadas:** [US5-8](../requisitos/01-selecao-validadores.md#us5-8)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `_newAccountsContract` | `address` | Endereço do novo contrato AccountRulesV2. |

*   **Acesso:** `onlyGovernance`
*   **Validações:**
    *   `_newAccountsContract != address(0)` (reverte com `InvalidAddress()`).
    *   `_newAccountsContract != address(accountsContract)` (reverte com `SameAddress()`).
    *   `_newAccountsContract` deve responder com sucesso à chamada externa `isAccountActive(address(0))` realizada dentro de um bloco `try/catch`. Caso falhe ou reverta, a execução é interrompida revertendo com `InvalidAccountsContract(_newAccountsContract)`.
*   **Efeitos:**
    *   Atualiza o endereço do contrato `accountsContract` com `_newAccountsContract`.
    *   Emite o evento `AccountsContractUpdated(address indexed oldAccounts, address indexed newAccounts)`.

### 3.2.19 `updateNodesContract`
**Assinatura:** `function updateNodesContract(address _newNodesContract) external`
*   **Histórias de Usuário Associadas:** [US5-9](../requisitos/01-selecao-validadores.md#us5-9)

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `_newNodesContract` | `address` | Endereço do novo contrato NodeRulesV2. |

*   **Acesso:** `onlyGovernance`
*   **Validações:**
    *   `_newNodesContract != address(0)` (reverte com `InvalidAddress()`).
    *   `_newNodesContract != address(nodesContract)` (reverte com `SameAddress()`).
    *   `_newNodesContract` deve responder com sucesso à chamada externa `allowedNodes(0)` realizada dentro de um bloco `try/catch`. Caso falhe ou reverta, a execução é interrompida revertendo com `InvalidNodesContract(_newNodesContract)`.
*   **Efeitos:**
    *   Atualiza o endereço do contrato `nodesContract` com `_newNodesContract`.
    *   Emite o evento `NodesContractUpdated(address indexed oldNodes, address indexed newNodes)`.
