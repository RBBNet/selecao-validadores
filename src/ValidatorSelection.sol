// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IValidatorSelection} from "src/interfaces/IValidatorSelection.sol";
import {IAdminProxy} from "src/interfaces/IAdminProxy.sol";
import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";
import {IAccountRulesV2, GLOBAL_ADMIN_ROLE, LOCAL_ADMIN_ROLE} from "src/interfaces/IAccountRulesV2.sol";
import {Governable} from "src/Governable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract ValidatorSelection is IValidatorSelection, Initializable, Governable, OwnableUpgradeable, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IAccountRulesV2 public accountsContract;
    INodeRulesV2 public nodesContract;

    EnumerableSet.AddressSet private elegibleValidators;
    EnumerableSet.AddressSet private operationalValidators;

    uint16 public blocksBetweenSelection;
    uint16 public blocksWithoutProposeThreshold;

    mapping(address => uint256) public lastBlockProposedBy;

    event MonitorExecuted();
    event SelectionExecuted();

    // em arrays indexados, é emitido o hash do array, então tem o custo de gas associado ao calculo do
    // keccak. além disso, não consigos obter a lista dos validadores removidos pelo evento, já que
    // vão estar "hash-ados". se não indexar, o gas é pago baseado no tamanho da lista que foi removida,
    // sendo 8 de gas por byte. neste caso, consumimos 32*(N+1) bytes, onde N é o tamaho da lista
    // (número de validadores removidos). ou seja, o custo de gas é dado por 32*(N+1)*8 = 256N+256.
    // sha3 tem 30 de custo base + 6 de gas por palavra. ou seja ((N+1)*6)+30 = 6N+36.
    // logo, indexar é 12~30x mais barato, porém dificulta leitura de eventos.
    // emitir um evento por endereço removido: 750N de custo de gas (muito mais caro).
    event ValidatorsRemoved(address[] indexed removed);

    error InactiveAccount(address account, string message);
    error NotLocalNode(bytes32 enodeHigh, bytes32 enodeLow);
    error NotElegibleNode(address nodeAddress);
    error NotOperationalNode(address nodeAddress);

    modifier onlyActiveAdmin() {
        if (
            !accountsContract.hasRole(GLOBAL_ADMIN_ROLE, _msgSender())
                && !accountsContract.hasRole(LOCAL_ADMIN_ROLE, _msgSender())
        ) {
            revert UnauthorizedAccess(_msgSender());
        }
        if (!accountsContract.isAccountActive(_msgSender())) {
            revert InactiveAccount(_msgSender(), "The account or the respective organization is not active");
        }
        _;
    }

    modifier onlySameOrganization(bytes32 enodeHigh, bytes32 enodeLow) {
        IAccountRulesV2.AccountData memory account = accountsContract.getAccount(_msgSender());
        uint256 nodeKey = _calculateKey(enodeHigh, enodeLow);
        (,,,, uint256 orgId,) = nodesContract.allowedNodes(nodeKey);
        if (account.orgId != orgId) revert NotLocalNode(enodeHigh, enodeLow);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IAdminProxy adminsProxy, IAccountRulesV2 _accountsContract, INodeRulesV2 _nodesContract)
        public
        initializer
    {
        __Governable_init(adminsProxy);
        __Ownable_init(_msgSender());
        accountsContract = _accountsContract;
        nodesContract = _nodesContract;
    }

    function getActiveValidators() external view returns (address[] memory) {
        return operationalValidators.values();
    }

    // usar ou não onlyActiveAdmin?
    // qualquer um pode contribuir com o monitoramento ou apenas as organizações?
    function monitorsValidators() external {
        // o evento facilita o rastreio das chamadas para atender o OLA, mas não é necessário
        // custo base de 375 de gas + 375 por topico indexado + 8 de gas por byte não indexado
        // neste caso, o custo seria N*375 de gas por blocos, onde N é o número de instituições
        // no nosso caso, seria 9*375 = 3375 por bloco, representando 0,02% do bloco, desconsiderando
        // os demais custos da transação
        emit MonitorExecuted();
        if (lastBlockProposedBy[block.coinbase] == block.number) {
            return;
        }
        _monitorsValidators();
        if (_isAtSelectionBlock()) {
            address[] memory selectedValidators = _selectValidators();
            if (_doesItNeedRemoval(selectedValidators)) {
                _removeOperationalValidators(selectedValidators);
            }
        }
    }

    function _monitorsValidators() internal {
        lastBlockProposedBy[block.coinbase] = block.number;
    }

    function _isAtSelectionBlock() internal view returns (bool) {
        return block.number % blocksBetweenSelection == 0;
    }

    function _selectValidators() internal returns (address[] memory) {
        uint256 numberOfOperationalValidators = operationalValidators.length();
        address[] memory auxArray = new address[](numberOfOperationalValidators);
        uint256 numberOfSelectedValidators;

        for (uint256 i; i < numberOfOperationalValidators;) {
            address candidateValidator = operationalValidators.at(i);
            uint256 lastBlockOfCandidateValidator = lastBlockProposedBy[candidateValidator];

            if (block.number - lastBlockOfCandidateValidator > blocksWithoutProposeThreshold) {
                auxArray[numberOfSelectedValidators++] = candidateValidator;
            }
            unchecked {
                ++i;
            }
        }

        address[] memory selectedValidators = new address[](numberOfSelectedValidators);
        for (uint256 i; i < numberOfSelectedValidators;) {
            selectedValidators[i] = auxArray[i];
            unchecked {
                ++i;
            }
        }

        emit SelectionExecuted();
        return selectedValidators;
    }

    function _doesItNeedRemoval(address[] memory selectedValidators) internal view returns (bool) {
        uint256 numberOfSelectedValidators = selectedValidators.length;
        if (numberOfSelectedValidators == 0) {
            return false;
        }

        uint256 numberOfOperationalValidators = operationalValidators.length();
        if (numberOfOperationalValidators <= 4) {
            return false;
        }

        uint256 minFail = (numberOfOperationalValidators % 3 == 1 ? 2 : 1);
        return numberOfSelectedValidators >= minFail;
    }

    function _removeOperationalValidators(address[] memory nonOperationalValidators) internal {
        uint256 numberOfNonOperationalValidators = nonOperationalValidators.length;
        for (uint256 i = 0; i < numberOfNonOperationalValidators;) {
            operationalValidators.remove(nonOperationalValidators[i]);
            unchecked {
                ++i;
            }
        }
        emit ValidatorsRemoved(nonOperationalValidators);
    }

    function setBlocksBetweenSelection(uint16 _blocksBetweenSelection) external onlyGovernance {
        blocksBetweenSelection = _blocksBetweenSelection;
    }

    function setBlocksWithoutProposeThreshold(uint16 _blocksWithoutProposeThreshold) external onlyGovernance {
        blocksWithoutProposeThreshold = _blocksWithoutProposeThreshold;
    }

    function addElegibleValidator(address validator) external onlyGovernance {
        elegibleValidators.add(validator);
    }

    function removeElegibleValidator(address validator) external onlyGovernance {
        if (elegibleValidators.contains(validator) == false) revert NotElegibleNode(validator);
        elegibleValidators.remove(validator);
    }

    function addOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow)
        external
        onlyActiveAdmin
        onlySameOrganization(enodeHigh, enodeLow)
    {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        if (elegibleValidators.contains(validator) == false) revert NotElegibleNode(validator);
        operationalValidators.add(validator);
    }

    function removeOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow)
        external
        onlyActiveAdmin
        onlySameOrganization(enodeHigh, enodeLow)
    {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        if (operationalValidators.contains(validator) == false) revert NotOperationalNode(validator);
        operationalValidators.remove(validator);
    }

    function _calculateAddress(bytes32 enodeHigh, bytes32 enodeLow) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))));
    }

    function _calculateKey(bytes32 enodeHigh, bytes32 enodeLow) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)));
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGovernance {}
}
