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

    uint256 public blocksBetweenSelection;
    uint256 public blocksWithoutProposeThreshold;
    uint256 public nextSelectionBlock;

    mapping(address => uint256) public lastBlockProposedBy;

    event MonitorExecuted();
    event SelectionExecuted();
    event ValidatorsRemoved(address[] removed);

    error InactiveAccount(address account);
    error NotLocalNode(bytes32 enodeHigh, bytes32 enodeLow);
    error NotElegibleNode(address nodeAddress);
    error NotOperationalNode(address nodeAddress);

    modifier onlyActiveAdmin() {
        _checkActiveAdmin();
        _;
    }

    modifier onlySameOrganization(bytes32 enodeHigh, bytes32 enodeLow) {
        _checkSameOrganization(enodeHigh, enodeLow);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IAdminProxy adminsProxy,
        IAccountRulesV2 _accountsContract,
        INodeRulesV2 _nodesContract,
        address memory initialElegibleValidators,
        uint256 _blocksBetweenSelection,
        uint256 _blocksWithoutProposeThreshold,
        uint256 _nextSelectionBlock
    ) public initializer {
        __Governable_init(adminsProxy);
        __Ownable_init(_msgSender());
        accountsContract = _accountsContract;
        nodesContract = _nodesContract;
        blocksBetweenSelection = _blocksBetweenSelection;
        blocksWithoutProposeThreshold = _blocksWithoutProposeThreshold;
        nextSelectionBlock = _nextSelectionBlock;
        _initElegibleValidators(initialElegibleValidators);
    }

    function _initElegibleValidators(address[] memory initialElegibleValidators) internal {
        uint256 initialElegibleValidatorsLength = initialElegibleValidators.length;
        for (uint256 i; i < initialElegibleValidatorsLength; i++) {
            elegibleValidators[i] = initialElegibleValidators[i];
        }
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
        address proposer = block.coinbase;
        uint256 blockNumber = block.number;
        if (lastBlockProposedBy[proposer] == blockNumber) {
            return;
        }
        _monitorsValidators(proposer, blockNumber);
        if (_isAtSelectionBlock(blockNumber)) {
            address[] memory selectedValidators = _selectValidators(blockNumber);
            if (_doesItNeedRemoval(selectedValidators)) {
                _removeOperationalValidators(selectedValidators);
            }
            _updateNextSelectionBlock();
        }
    }

    function _monitorsValidators(address proposer, uint256 blockNumber) internal {
        lastBlockProposedBy[proposer] = blockNumber;
    }

    function _isAtSelectionBlock(uint256 blockNumber) internal view returns (bool) {
        return blockNumber == nextSelectionBlock;
    }

    function _selectValidators(uint256 blockNumber) internal returns (address[] memory) {
        uint256 numberOfOperationalValidators = operationalValidators.length();
        address[] memory auxArray = new address[](numberOfOperationalValidators);
        uint256 numberOfSelectedValidators;

        for (uint256 i; i < numberOfOperationalValidators;) {
            address candidateValidator = operationalValidators.at(i);
            uint256 lastBlockOfCandidateValidator = lastBlockProposedBy[candidateValidator];

            if (blockNumber - lastBlockOfCandidateValidator > blocksWithoutProposeThreshold) {
                auxArray[numberOfSelectedValidators++] = candidateValidator;
            }

            // https://www.soliditylang.org/blog/2023/10/25/solidity-0.8.22-release-announcement/
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
        uint256 numberOfRemainingValidators = numberOfOperationalValidators - numberOfSelectedValidators;
        if (numberOfRemainingValidators < 4) {
            return false;
        }
        return true;
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

    function setBlocksBetweenSelection(uint256 _blocksBetweenSelection) external onlyGovernance {
        blocksBetweenSelection = _blocksBetweenSelection;
    }

    function setNextSelectionBlock(uint256 _nextSelectionBlock) external onlyGovernance {
        nextSelectionBlock = _nextSelectionBlock;
    }

    function _updateNextSelectionBlock() internal {
        nextSelectionBlock += blocksBetweenSelection;
    }

    function setBlocksWithoutProposeThreshold(uint256 _blocksWithoutProposeThreshold) external onlyGovernance {
        blocksWithoutProposeThreshold = _blocksWithoutProposeThreshold;
    }

    function addElegibleValidator(address validator) public onlyGovernance {
        elegibleValidators.add(validator);
    }

    function addElegibleValidator(bytes32 enodeHigh, bytes32 enodeLow) external onlyGovernance {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        addElegibleValidator(validator);
    }

    function removeElegibleValidator(address validator) public onlyGovernance {
        if (!elegibleValidators.contains(validator)) revert NotElegibleNode(validator);
        elegibleValidators.remove(validator);
    }

    function removeElegibleValidator(bytes32 enodeHigh, bytes32 enodeLow) external onlyGovernance {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        removeElegibleValidator(validator);
    }

    function addOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow)
        external
        onlyActiveAdmin
        onlySameOrganization(enodeHigh, enodeLow)
    {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        if (!elegibleValidators.contains(validator)) revert NotElegibleNode(validator);
        operationalValidators.add(validator);
    }

    function addOperationalValidator(address validator) external onlyGovernance {
        if (!elegibleValidators.contains(validator)) revert NotElegibleNode(validator);
        operationalValidators.add(validator);
    }

    function removeOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow)
        external
        onlyActiveAdmin
        onlySameOrganization(enodeHigh, enodeLow)
    {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        if (!operationalValidators.contains(validator)) revert NotOperationalNode(validator);
        operationalValidators.remove(validator);
    }

    function removeOperationalValidator(address validator) external onlyGovernance {
        if (!operationalValidators.contains(validator)) revert NotOperationalNode(validator);
        operationalValidators.remove(validator);
    }

    function _checkActiveAdmin() internal view {
        if (
            !accountsContract.hasRole(GLOBAL_ADMIN_ROLE, _msgSender())
                && !accountsContract.hasRole(LOCAL_ADMIN_ROLE, _msgSender())
        ) {
            revert UnauthorizedAccess(_msgSender());
        }
        if (!accountsContract.isAccountActive(_msgSender())) {
            revert InactiveAccount(_msgSender());
        }
    }

    function _checkSameOrganization(bytes32 enodeHigh, bytes32 enodeLow) internal view {
        IAccountRulesV2.AccountData memory account = accountsContract.getAccount(_msgSender());
        uint256 nodeKey = _calculateKey(enodeHigh, enodeLow);
        (,,,, uint256 orgId,) = nodesContract.allowedNodes(nodeKey);
        if (account.orgId != orgId) revert NotLocalNode(enodeHigh, enodeLow);
    }

    function _calculateKey(bytes32 enodeHigh, bytes32 enodeLow) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)));
    }

    function _calculateAddress(bytes32 enodeHigh, bytes32 enodeLow) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))));
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGovernance {}
}
