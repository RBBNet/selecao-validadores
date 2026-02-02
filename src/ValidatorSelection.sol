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

    EnumerableSet.AddressSet private eligibleValidators;
    EnumerableSet.AddressSet private operationalValidators;

    uint256 public blocksBetweenSelection;
    uint256 public blocksWithoutProposeThreshold;
    uint256 public nextSelectionBlock;
    uint256 public batchSize;
    uint256 public selectionCursor;
    bool public selectionInProgress;
    uint256 public selectionReferenceBlock;

    mapping(address => uint256) public lastBlockProposedBy;

    uint256 public constant MIN_NUMBER_OF_VALIDATORS = 4;
    uint256 public constant DEFAULT_BATCH_SIZE = 50;
    uint256 public constant MIN_BATCH_SIZE = 10;
    uint256 public constant MAX_BATCH_SIZE = 500;
    uint256 public constant MIN_BLOCKS_BETWEEN_SELECTION = 10;
    uint256 public constant MAX_BLOCKS_BETWEEN_SELECTION = 100000;
    uint256 public constant MIN_BLOCKS_WITHOUT_PROPOSE_THRESHOLD = 10;
    uint256 public constant MAX_BLOCKS_WITHOUT_PROPOSE_THRESHOLD = 1000000;
    uint256 public constant SELECTION_TIMEOUT_BLOCKS = 1000;

    event MonitorExecuted();
    event SelectionExecuted(uint256 indexed blockNumber, uint256 cursor, uint256 processed, uint256 found);
    event SelectionStarted(uint256 indexed blockNumber, uint256 totalValidators);
    event SelectionCompleted(uint256 indexed blockNumber, uint256 totalProcessed);
    event ValidatorProposalTracked(address indexed validator, uint256 blockNumber);
    event EligibleValidatorAdded(address indexed validator);
    event EligibleValidatorRemoved(address indexed validator);
    event OperationalValidatorAdded(address indexed validator, uint256 initialBlock);
    event OperationalValidatorRemoved(address indexed validator, address indexed removedBy);
    event ValidatorsRemoved(address[] removed);
    event BlocksBetweenSelectionUpdated(uint256 oldValue, uint256 newValue);
    event BlocksWithoutProposeThresholdUpdated(uint256 oldValue, uint256 newValue);
    event NextSelectionBlockUpdated(uint256 oldValue, uint256 newValue);
    event BatchSizeUpdated(uint256 oldValue, uint256 newValue);
    event SelectionReset(uint256 indexed blockNumber);
    event ContractInitialized(
        address indexed accountsContract,
        address indexed nodesContract,
        uint256 blocksBetweenSelection,
        uint256 blocksWithoutProposeThreshold,
        uint256 nextSelectionBlock,
        uint256 initialValidatorsCount
    );
    event ContractUpgraded(address indexed newImplementation, address indexed upgrader);

    error InactiveAccount(address account);
    error NotLocalNode(bytes32 enodeHigh, bytes32 enodeLow);
    error NotEligibleNode(address nodeAddress);
    error NotOperationalNode(address nodeAddress);
    error FewEligibleValidators();
    error InvalidValidatorAddress(address validator);
    error DuplicateValidator(address validator);
    error InvalidConfigurationValue(string parameter, uint256 value);
    error CannotModifyDuringSelection();
    error NoSelectionInProgress();
    error SelectionNotTimedOut();

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
        address[] memory initialEligibleValidators,
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
        batchSize = DEFAULT_BATCH_SIZE;
        _initEligibleValidators(initialEligibleValidators);
        
        emit ContractInitialized(
            address(_accountsContract),
            address(_nodesContract),
            _blocksBetweenSelection,
            _blocksWithoutProposeThreshold,
            _nextSelectionBlock,
            initialEligibleValidators.length
        );
    }

    function _initEligibleValidators(address[] memory initialEligibleValidators) internal {
        uint256 initialEligibleValidatorsLength = initialEligibleValidators.length;
        if (initialEligibleValidatorsLength < MIN_NUMBER_OF_VALIDATORS) revert FewEligibleValidators();
        
        for (uint256 i; i < initialEligibleValidatorsLength; i++) {
            address validator = initialEligibleValidators[i];
            
            if (validator == address(0)) revert InvalidValidatorAddress(validator);
            
            bool added = eligibleValidators.add(validator);
            if (!added) revert DuplicateValidator(validator);
        }
    }

    function getActiveValidators() external view returns (address[] memory) {
        return operationalValidators.values();
    }

    function getEligibleValidators() external view returns (address[] memory) {
        return eligibleValidators.values();
    }

    function getEligibleValidatorsCount() external view returns (uint256) {
        return eligibleValidators.length();
    }

    function getOperationalValidatorsCount() external view returns (uint256) {
        return operationalValidators.length();
    }

    function isEligibleValidator(address validator) external view returns (bool) {
        return eligibleValidators.contains(validator);
    }

    function isOperationalValidator(address validator) external view returns (bool) {
        return operationalValidators.contains(validator);
    }

    function monitorsValidators() external {
        address proposer = block.coinbase;
        uint256 blockNumber = block.number;

        if (lastBlockProposedBy[proposer] != blockNumber) {
            _monitorsValidators(proposer, blockNumber);
        }

        if (blockNumber < nextSelectionBlock && !selectionInProgress) {
            return;
        }

        if (blockNumber >= nextSelectionBlock && !selectionInProgress) {
            selectionInProgress = true;
            selectionCursor = 0;
            selectionReferenceBlock = nextSelectionBlock;
            emit SelectionStarted(blockNumber, operationalValidators.length());
        }

        if (selectionInProgress) {
            uint256 currentTotal = operationalValidators.length();
            uint256 cursor = selectionCursor;
            uint256 batch = batchSize;

            if (cursor >= currentTotal) {
                _finishSelection(blockNumber, cursor);
                return;
            }

            (address[] memory batchArr, uint256 newCursor) = _selectValidators(
                selectionReferenceBlock,
                cursor,
                batch,
                currentTotal
            );

            if (batchArr.length > 0 && _doesItNeedRemoval(batchArr, currentTotal)) {
                _removeOperationalValidators(batchArr);
            }

            selectionCursor = newCursor;

            if (newCursor >= operationalValidators.length()) {
                _finishSelection(blockNumber, newCursor);
            }
        }
    }

    function _monitorsValidators(address proposer, uint256 blockNumber) internal {
        lastBlockProposedBy[proposer] = blockNumber;
        emit ValidatorProposalTracked(proposer, blockNumber);
    }

    function _finishSelection(uint256 blockNumber, uint256 totalProcessed) internal {
        selectionInProgress = false;
        selectionCursor = 0;
        uint256 oldValue = nextSelectionBlock;
        nextSelectionBlock = selectionReferenceBlock + blocksBetweenSelection;
        
        emit SelectionCompleted(blockNumber, totalProcessed);
        emit NextSelectionBlockUpdated(oldValue, nextSelectionBlock);
    }

    function _selectValidators(
        uint256 blockNumber,
        uint256 cursor,
        uint256 count,
        uint256 totalValidators
    ) internal returns (address[] memory result, uint256 newCursor) {
        if (cursor >= totalValidators) {
            return (new address[](0), cursor);
        }

        uint256 endIndex = cursor + count;
        if (endIndex > totalValidators) {
            endIndex = totalValidators;
        }

        uint256 threshold = blocksWithoutProposeThreshold;

        uint256 matches = 0;
        for (uint256 i = cursor; i < endIndex; i++) {
            address candidate = operationalValidators.at(i);
            uint256 lastBlock = lastBlockProposedBy[candidate];
            if (lastBlock != 0 && blockNumber >= lastBlock) {
                unchecked {
                    if (blockNumber - lastBlock > threshold) {
                        ++matches;
                    }
                }
            }
        }

        result = new address[](matches);

        if (matches > 0) {
            uint256 resultIndex = 0;
            for (uint256 i = cursor; i < endIndex; i++) {
                address candidate = operationalValidators.at(i);
                uint256 lastBlock = lastBlockProposedBy[candidate];
                if (lastBlock != 0 && blockNumber >= lastBlock) {
                    unchecked {
                        if (blockNumber - lastBlock > threshold) {
                            result[resultIndex] = candidate;
                            ++resultIndex;
                        }
                    }
                }
            }
        }

        emit SelectionExecuted(blockNumber, cursor, endIndex - cursor, matches);

        return (result, endIndex);
    }

    function _doesItNeedRemoval(address[] memory selectedValidators, uint256 currentTotal) internal pure returns (bool) {
        uint256 numberOfSelectedValidators = selectedValidators.length;
        if (numberOfSelectedValidators == 0) {
            return false;
        }

        uint256 numberOfRemainingValidators = currentTotal - numberOfSelectedValidators;
        if (numberOfRemainingValidators < MIN_NUMBER_OF_VALIDATORS) {
            return false;
        }

        return true;
    }

    function _removeOperationalValidators(address[] memory nonOperationalValidators) internal {
        uint256 numberOfNonOperationalValidators = nonOperationalValidators.length;
        for (uint256 i = 0; i < numberOfNonOperationalValidators; i++) {
            address validator = nonOperationalValidators[i];
            operationalValidators.remove(validator);
            delete lastBlockProposedBy[validator];            
            emit OperationalValidatorRemoved(validator, address(this));
        }
        emit ValidatorsRemoved(nonOperationalValidators);
    }

    function setBlocksBetweenSelection(uint256 _blocksBetweenSelection) external onlyGovernance {
        if (_blocksBetweenSelection < MIN_BLOCKS_BETWEEN_SELECTION) {
            revert InvalidConfigurationValue("blocksBetweenSelection", _blocksBetweenSelection);
        }
        if (_blocksBetweenSelection > MAX_BLOCKS_BETWEEN_SELECTION) {
            revert InvalidConfigurationValue("blocksBetweenSelection", _blocksBetweenSelection);
        }
        uint256 oldValue = blocksBetweenSelection;
        blocksBetweenSelection = _blocksBetweenSelection;
        emit BlocksBetweenSelectionUpdated(oldValue, _blocksBetweenSelection);
    }

    function setNextSelectionBlock(uint256 _nextSelectionBlock) external onlyGovernance {
        if (_nextSelectionBlock <= block.number) {
            revert InvalidConfigurationValue("nextSelectionBlock", _nextSelectionBlock);
        }
        uint256 oldValue = nextSelectionBlock;
        nextSelectionBlock = _nextSelectionBlock;
        emit NextSelectionBlockUpdated(oldValue, _nextSelectionBlock);
    }

    function setBlocksWithoutProposeThreshold(uint256 _blocksWithoutProposeThreshold) external onlyGovernance {
        if (_blocksWithoutProposeThreshold < MIN_BLOCKS_WITHOUT_PROPOSE_THRESHOLD) {
            revert InvalidConfigurationValue("blocksWithoutProposeThreshold", _blocksWithoutProposeThreshold);
        }
        if (_blocksWithoutProposeThreshold > MAX_BLOCKS_WITHOUT_PROPOSE_THRESHOLD) {
            revert InvalidConfigurationValue("blocksWithoutProposeThreshold", _blocksWithoutProposeThreshold);
        }
        
        uint256 oldValue = blocksWithoutProposeThreshold;
        blocksWithoutProposeThreshold = _blocksWithoutProposeThreshold;
        emit BlocksWithoutProposeThresholdUpdated(oldValue, _blocksWithoutProposeThreshold);
    }

    function setBatchSize(uint256 _batchSize) external onlyGovernance {
        if (_batchSize < MIN_BATCH_SIZE) {
            revert InvalidConfigurationValue("batchSize", _batchSize);
        }
        if (_batchSize > MAX_BATCH_SIZE) {
            revert InvalidConfigurationValue("batchSize", _batchSize);
        }
        
        uint256 oldValue = batchSize;
        batchSize = _batchSize;
        emit BatchSizeUpdated(oldValue, _batchSize);
    }

    function _addEligibleValidator(address validator) internal {
        if (validator == address(0)) revert InvalidValidatorAddress(validator);
        
        bool added = eligibleValidators.add(validator);
        if (!added) revert DuplicateValidator(validator);
        
        emit EligibleValidatorAdded(validator);
    }

    function addEligibleValidator(address validator) external onlyGovernance {
        _addEligibleValidator(validator);
    }


    function addEligibleValidatorByEnode(bytes32 enodeHigh, bytes32 enodeLow) external onlyGovernance {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        _addEligibleValidator(validator);
    }

    function _removeEligibleValidator(address validator) internal {
        if (!eligibleValidators.contains(validator)) revert NotEligibleNode(validator);
        eligibleValidators.remove(validator);
        emit EligibleValidatorRemoved(validator);
    }

    function removeEligibleValidator(address validator) external onlyGovernance {
        _removeEligibleValidator(validator);
    }

    function removeEligibleValidatorByEnode(bytes32 enodeHigh, bytes32 enodeLow) external onlyGovernance {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        _removeEligibleValidator(validator);
    }

    function _addOperationalValidator(address validator) internal {
        if (validator == address(0)) revert InvalidValidatorAddress(validator);
        if (!eligibleValidators.contains(validator)) revert NotEligibleNode(validator);
        
        bool added = operationalValidators.add(validator);
        if (!added) revert DuplicateValidator(validator);
        
        lastBlockProposedBy[validator] = block.number;
        
        emit OperationalValidatorAdded(validator, block.number);
    }

    function addOperationalValidatorByEnode(bytes32 enodeHigh, bytes32 enodeLow)
        external
        onlyActiveAdmin
        onlySameOrganization(enodeHigh, enodeLow)
    {
        if (selectionInProgress) revert CannotModifyDuringSelection();
        address validator = _calculateAddress(enodeHigh, enodeLow);
        _addOperationalValidator(validator);
    }

    function addOperationalValidator(address validator) external onlyGovernance {
        if (selectionInProgress) revert CannotModifyDuringSelection();
        _addOperationalValidator(validator);
    }

    function _removeOperationalValidator(address validator, address removedBy) internal {
        if (!operationalValidators.contains(validator)) revert NotOperationalNode(validator);
        operationalValidators.remove(validator);
        
        delete lastBlockProposedBy[validator];
        
        emit OperationalValidatorRemoved(validator, removedBy);
    }

    function removeOperationalValidatorByEnode(bytes32 enodeHigh, bytes32 enodeLow)
        external
        onlyActiveAdmin
        onlySameOrganization(enodeHigh, enodeLow)
    {
        if (selectionInProgress) revert CannotModifyDuringSelection();
        address validator = _calculateAddress(enodeHigh, enodeLow);
        _removeOperationalValidator(validator, _msgSender());
    }

    function removeOperationalValidator(address validator) external onlyGovernance {
        if (selectionInProgress) revert CannotModifyDuringSelection();
        _removeOperationalValidator(validator, _msgSender());
    }

    function resetStuckSelection() external onlyGovernance {
        if (!selectionInProgress) {
            revert NoSelectionInProgress();
        }
        
        uint256 blocksSinceStart = block.number - selectionReferenceBlock;
        if (blocksSinceStart < SELECTION_TIMEOUT_BLOCKS) {
            revert SelectionNotTimedOut();
        }
        
        selectionInProgress = false;
        selectionCursor = 0;
        nextSelectionBlock = block.number + blocksBetweenSelection;
        
        emit SelectionReset(block.number);
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
        uint256 nodeKey = uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)));
        (,,,, uint256 orgId,) = nodesContract.allowedNodes(nodeKey);
        if (account.orgId != orgId) revert NotLocalNode(enodeHigh, enodeLow);
    }

    function _calculateAddress(bytes32 enodeHigh, bytes32 enodeLow) internal pure returns (address) {
        address result;
        assembly {
            mstore(0x00, enodeHigh)
            mstore(0x20, enodeLow)
            result := and(keccak256(0x00, 0x40), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGovernance {
        emit ContractUpgraded(newImplementation, _msgSender());
    }
}
