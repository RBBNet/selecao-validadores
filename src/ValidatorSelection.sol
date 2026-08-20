// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IValidatorSelection, OperationMode} from "src/interfaces/IValidatorSelection.sol";
import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";
import {IAccountRulesV2, GLOBAL_ADMIN_ROLE, LOCAL_ADMIN_ROLE} from "src/interfaces/IAccountRulesV2.sol";
import {Governable} from "permissioning/Governable.sol";
import {AdminProxy} from "permissioning/AdminProxy.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract ValidatorSelection is IValidatorSelection, Governable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IAccountRulesV2 public accountsContract;
    INodeRulesV2 public nodesContract;

    EnumerableSet.AddressSet private eligibleValidators;
    EnumerableSet.AddressSet private operationalValidators;
    EnumerableSet.AddressSet private protectedValidators;

    OperationMode public operationMode;

    uint256 public blocksBetweenSelection;
    uint256 public blocksWithoutProposeThreshold;
    uint256 public nextSelectionBlock;
    uint256 public cycleStartBlock;
    uint256 public lastMonitoredBlock;

    mapping(address => uint256) public lastBlockProposedBy;

    uint256 public constant MIN_INITIAL_ELIGIBLE_VALIDATORS = 1;
    uint256 public constant MIN_BFT_OPERATIONAL_VALIDATORS = 4;
    uint256 public constant MIN_OPERATIONAL_VALIDATORS = 1;

    event MonitorExecuted(address indexed executor, uint256 indexed blockNumber);
    event SelectionExecuted(address[] operationalValidators);
    event OperationModeChanged(OperationMode indexed mode);
    event OperationalValidatorAdded(address indexed validator);
    event OperationalValidatorRemoved(address indexed validator);
    event OperationalValidatorManuallyRemoved(address indexed validator);
    event EligibleValidatorAdded(address indexed validator, bool indexed activateAsOperational);
    event EligibleValidatorRemoved(address indexed validator);
    event SelectionParametersUpdated(uint256 blocksBetweenSelection, uint256 blocksWithoutProposeThreshold);
    event AdminContractUpdated(address indexed oldAdmin, address indexed newAdmin);
    event AccountsContractUpdated(address indexed oldAccounts, address indexed newAccounts);
    event NodesContractUpdated(address indexed oldNodes, address indexed newNodes);

    error InvalidAddress();
    error InactiveAccount(address account);
    error NotLocalNode(bytes32 enodeHigh, bytes32 enodeLow);
    error InvalidValidatorAddress(address nodeAddress);
    error NotEligibleNode(address nodeAddress);
    error AlreadyEligibleNode(address nodeAddress);
    error NotOperationalNode(address nodeAddress);
    error AlreadyOperationalNode(address nodeAddress);
    error FewEligibleValidators();
    error FewOperationalValidators();
    error InvalidBlocksBetweenSelection();
    error InvalidBlocksWithoutProposeThreshold();
    error SameAddress(address current);
    error InvalidAdminContract(address addr);
    error InvalidAccountsContract(address addr);
    error InvalidNodesContract(address addr);
    error InvalidOperationMode();

    constructor(
        AdminProxy adminsProxy,
        IAccountRulesV2 _accountsContract,
        INodeRulesV2 _nodesContract,
        address[] memory initialEligibleValidators,
        uint256 _blocksBetweenSelection,
        uint256 _blocksWithoutProposeThreshold,
        uint256 _nextSelectionBlock
    ) Governable(adminsProxy) {
        if (address(_accountsContract) == address(0) || address(_nodesContract) == address(0)) {
            revert InvalidAddress();
        }
        accountsContract = _accountsContract;
        nodesContract = _nodesContract;
        _initEligibleValidators(initialEligibleValidators);
        _validateSelectionParameters(_blocksBetweenSelection, _blocksWithoutProposeThreshold);
        blocksBetweenSelection = _blocksBetweenSelection;
        blocksWithoutProposeThreshold = _blocksWithoutProposeThreshold;
        nextSelectionBlock = _nextSelectionBlock;
        cycleStartBlock = block.number;
    }

    function _initEligibleValidators(address[] memory initialEligibleValidators) internal {
        uint256 initialEligibleValidatorsLength = initialEligibleValidators.length;
        if (initialEligibleValidatorsLength < MIN_INITIAL_ELIGIBLE_VALIDATORS) revert FewEligibleValidators();

        for (uint256 i; i < initialEligibleValidatorsLength;) {
            address validator = initialEligibleValidators[i];
            if (validator == address(0)) revert InvalidValidatorAddress(validator);
            if (!eligibleValidators.add(validator)) revert AlreadyEligibleNode(validator);

            operationalValidators.add(validator);
            protectedValidators.add(validator);

            unchecked {
                ++i;
            }
        }
    }

    function getValidators() external view returns (address[] memory) {
        return operationalValidators.values();
    }

    function getEligibleValidators() external view returns (address[] memory) {
        return eligibleValidators.values();
    }

    function getProtectedValidators() external view returns (address[] memory) {
        return protectedValidators.values();
    }

    function isEligible(address validator) external view returns (bool) {
        return eligibleValidators.contains(validator);
    }

    function isOperational(address validator) external view returns (bool) {
        return operationalValidators.contains(validator);
    }

    function isProtected(address validator) external view returns (bool) {
        return protectedValidators.contains(validator);
    }

    function setOperationMode(OperationMode newMode) external onlyGovernance {
        if (newMode != OperationMode.Manual && newMode != OperationMode.Automatic) {
            revert InvalidOperationMode();
        }
        operationMode = newMode;
        if (newMode == OperationMode.Automatic) {
            _protectOperationalValidators();
            _startNewCycle(block.number);
            lastMonitoredBlock = 0;
        }
        emit OperationModeChanged(newMode);
    }

    function executeMonitoring() external {
        emit MonitorExecuted(msg.sender, block.number);
        if (operationMode != OperationMode.Automatic) {
            return;
        }
        uint256 blockNumber = block.number;
        if (lastMonitoredBlock == blockNumber) {
            return;
        }
        lastMonitoredBlock = blockNumber;
        lastBlockProposedBy[block.coinbase] = blockNumber;
        if (_isAtSelectionBlock(blockNumber)) {
            _selectValidators(blockNumber);
            _clearProtectedValidators();
            _startNewCycle(blockNumber);
        }
    }

    function _isAtSelectionBlock(uint256 blockNumber) internal view returns (bool) {
        return blockNumber >= nextSelectionBlock;
    }

    function _selectValidators(uint256 blockNumber) internal {
        address[] memory candidateValidators = operationalValidators.values();
        uint256 numberOfCandidateValidators = candidateValidators.length;
        uint256 removed;

        for (uint256 i; i < numberOfCandidateValidators;) {
            address candidateValidator = candidateValidators[i];
            if (blockNumber - _lastActivity(candidateValidator) <= blocksWithoutProposeThreshold) {
                unchecked {
                    ++i;
                }
                continue;
            }
            if (protectedValidators.contains(candidateValidator)) {
                unchecked {
                    ++i;
                }
                continue;
            }
            if (numberOfCandidateValidators - removed <= MIN_BFT_OPERATIONAL_VALIDATORS) {
                break;
            }
            operationalValidators.remove(candidateValidator);
            emit OperationalValidatorRemoved(candidateValidator);
            unchecked {
                ++i;
                ++removed;
            }
        }

        if (removed > 0) {
            emit SelectionExecuted(operationalValidators.values());
        } else {
            emit SelectionExecuted(candidateValidators);
        }
    }

    function _lastActivity(address validator) internal view returns (uint256) {
        uint256 lastBlockProposed = lastBlockProposedBy[validator];
        return lastBlockProposed > cycleStartBlock ? lastBlockProposed : cycleStartBlock;
    }

    function _startNewCycle(uint256 blockNumber) internal {
        cycleStartBlock = blockNumber;
        nextSelectionBlock = blockNumber + blocksBetweenSelection;
    }

    function _clearProtectedValidators() internal {
        protectedValidators.clear();
    }
    
    function setSelectionParameters(uint256 _blocksBetweenSelection, uint256 _blocksWithoutProposeThreshold)
        external
        onlyGovernance
    {
        _validateSelectionParameters(_blocksBetweenSelection, _blocksWithoutProposeThreshold);
        blocksBetweenSelection = _blocksBetweenSelection;
        blocksWithoutProposeThreshold = _blocksWithoutProposeThreshold;
        _protectOperationalValidators();
        _startNewCycle(block.number);
        emit SelectionParametersUpdated(_blocksBetweenSelection, _blocksWithoutProposeThreshold);
    }

    function _validateSelectionParameters(uint256 _blocksBetweenSelection, uint256 _blocksWithoutProposeThreshold)
        internal
        view
    {
        if (_blocksBetweenSelection < 1) revert InvalidBlocksBetweenSelection();
        if (_blocksWithoutProposeThreshold < eligibleValidators.length()) {
            revert InvalidBlocksWithoutProposeThreshold();
        }
    }

    function _protectOperationalValidators() internal {
        address[] memory operational = operationalValidators.values();
        uint256 operationalLength = operational.length;
        for (uint256 i; i < operationalLength;) {
            protectedValidators.add(operational[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addEligibleValidatorByAddress(address validator, bool activateAsOperational) public onlyGovernance {
        if (validator == address(0)) revert InvalidValidatorAddress(validator);
        if (!eligibleValidators.add(validator)) revert AlreadyEligibleNode(validator);
        emit EligibleValidatorAdded(validator, activateAsOperational);
        if (activateAsOperational) {
            _addOperationalValidator(validator);
        }
        _adjustBlocksWithoutProposeThreshold();
    }

    function addEligibleValidator(bytes32 enodeHigh, bytes32 enodeLow, bool activateAsOperational)
        external
        onlyGovernance
    {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        addEligibleValidatorByAddress(validator, activateAsOperational);
    }

    function _adjustBlocksWithoutProposeThreshold() internal {
        uint256 numberOfEligibleValidators = eligibleValidators.length();
        if (blocksWithoutProposeThreshold < numberOfEligibleValidators) {
            blocksWithoutProposeThreshold = numberOfEligibleValidators;
            emit SelectionParametersUpdated(blocksBetweenSelection, blocksWithoutProposeThreshold);
        }
    }

    function removeEligibleValidatorByAddress(address validator) public onlyGovernance {
        if (!eligibleValidators.contains(validator)) revert NotEligibleNode(validator);
        if (operationalValidators.contains(validator)) {
            _removeOperationalValidator(validator, MIN_OPERATIONAL_VALIDATORS);
        }
        eligibleValidators.remove(validator);
        emit EligibleValidatorRemoved(validator);
    }

    function removeEligibleValidator(bytes32 enodeHigh, bytes32 enodeLow) external onlyGovernance {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        removeEligibleValidatorByAddress(validator);
    }

    function addOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow) external {
        if (!admins.isAuthorized(msg.sender)) {
            _checkActiveAdmin();
            _checkSameOrganization(enodeHigh, enodeLow);
        }
        address validator = _calculateAddress(enodeHigh, enodeLow);
        _addOperationalValidator(validator);
    }

    function addOperationalValidatorByAddress(address validator) external onlyGovernance {
        _addOperationalValidator(validator);
    }

    function _addOperationalValidator(address validator) internal {
        if (!eligibleValidators.contains(validator)) revert NotEligibleNode(validator);
        if (operationalValidators.contains(validator)) revert AlreadyOperationalNode(validator);
        operationalValidators.add(validator);
        protectedValidators.add(validator);
        emit OperationalValidatorAdded(validator);
    }

    function removeOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow) external onlyGovernance {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        _removeOperationalValidator(validator, MIN_OPERATIONAL_VALIDATORS);
    }

    function removeOperationalValidatorByAddress(address validator) external onlyGovernance {
        _removeOperationalValidator(validator, MIN_OPERATIONAL_VALIDATORS);
    }

    function removeOperationalValidatorByAdmin(bytes32 enodeHigh, bytes32 enodeLow) external {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        _checkActiveAdmin();
        _checkSameOrganization(enodeHigh, enodeLow);
        _removeOperationalValidator(validator, MIN_BFT_OPERATIONAL_VALIDATORS);
    }

    function _removeOperationalValidator(address validator, uint256 minRemainingValidators) internal {
        if (!operationalValidators.contains(validator)) revert NotOperationalNode(validator);
        if (operationalValidators.length() - 1 < minRemainingValidators) revert FewOperationalValidators();
        operationalValidators.remove(validator);
        protectedValidators.remove(validator);
        emit OperationalValidatorManuallyRemoved(validator);
    }

    function updateAdminContract(address _newAdmin) external onlyGovernance {
        if (_newAdmin == address(0)) revert InvalidAddress();
        if (_newAdmin == address(admins)) revert SameAddress(_newAdmin);
        try AdminProxy(_newAdmin).isAuthorized(address(0)) returns (bool authorized) {
            if (authorized) revert InvalidAdminContract(_newAdmin);
        } catch {
            revert InvalidAdminContract(_newAdmin);
        }
        address oldAdmin = address(admins);
        admins = AdminProxy(_newAdmin);
        emit AdminContractUpdated(oldAdmin, _newAdmin);
    }

    function updateAccountsContract(address _newAccountsContract) external onlyGovernance {
        if (_newAccountsContract == address(0)) revert InvalidAddress();
        if (_newAccountsContract == address(accountsContract)) revert SameAddress(_newAccountsContract);
        try IAccountRulesV2(_newAccountsContract).isAccountActive(address(0)) returns (bool active) {
            if (active) revert InvalidAccountsContract(_newAccountsContract);
        } catch {
            revert InvalidAccountsContract(_newAccountsContract);
        }
        address oldAccounts = address(accountsContract);
        accountsContract = IAccountRulesV2(_newAccountsContract);
        emit AccountsContractUpdated(oldAccounts, _newAccountsContract);
    }

    function updateNodesContract(address _newNodesContract) external onlyGovernance {
        if (_newNodesContract == address(0)) revert InvalidAddress();
        if (_newNodesContract == address(nodesContract)) revert SameAddress(_newNodesContract);
        try INodeRulesV2(_newNodesContract).allowedNodes(0) returns (
            bytes32, bytes32, INodeRulesV2.NodeType, string memory, uint256 orgId, bool active
        ) {
            if (orgId != 0 || active) revert InvalidNodesContract(_newNodesContract);
        } catch {
            revert InvalidNodesContract(_newNodesContract);
        }
        address oldNodes = address(nodesContract);
        nodesContract = INodeRulesV2(_newNodesContract);
        emit NodesContractUpdated(oldNodes, _newNodesContract);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IValidatorSelection).interfaceId;
    }

    function _checkActiveAdmin() internal view {
        if (
            !accountsContract.hasRole(GLOBAL_ADMIN_ROLE, msg.sender)
                && !accountsContract.hasRole(LOCAL_ADMIN_ROLE, msg.sender)
        ) {
            revert UnauthorizedAccess(msg.sender);
        }
        if (!accountsContract.isAccountActive(msg.sender)) {
            revert InactiveAccount(msg.sender);
        }
    }

    function _checkSameOrganization(bytes32 enodeHigh, bytes32 enodeLow) internal view {
        IAccountRulesV2.AccountData memory account = accountsContract.getAccount(msg.sender);
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
}
