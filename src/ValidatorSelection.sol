// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.24;
import {IAdminProxy} from "src/interfaces/IAdminProxy.sol";
import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";
import {IAccountRulesV2, GLOBAL_ADMIN_ROLE, LOCAL_ADMIN_ROLE} from "src/interfaces/IAccountRulesV2.sol";
import {Governable} from "src/Governable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract ValidatorSelection is
    Initializable,
    Governable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    IAccountRulesV2 public accountsContract;
    INodeRulesV2 public nodesContract;

    EnumerableSet.AddressSet private elegibleValidators;
    EnumerableSet.AddressSet private operationalValidators;

    uint256 public blocksBetweenSelection;
    uint256 public blocksWithoutProposeThreshold;
    uint256 public nextSelectionBlock;

    mapping(address => uint256) public lastBlockProposedBy;

    uint256 public constant MIN_NUMBER_OF_VALIDATORS = 4;

    event MonitorExecuted();
    event SelectionExecuted();
    event ValidatorProposalTracked(
        address indexed validator,
        uint256 blockNumber
    );
    event EligibleValidatorAdded(address indexed validator);
    event EligibleValidatorRemoved(address indexed validator);
    event OperationalValidatorAdded(
        address indexed validator,
        uint256 initialBlock
    );
    event OperationalValidatorRemoved(
        address indexed validator,
        address indexed removedBy
    );
    event ValidatorsRemoved(address[] removed);
    event BlocksBetweenSelectionUpdated(uint256 oldValue, uint256 newValue);
    event BlocksWithoutProposeThresholdUpdated(
        uint256 oldValue,
        uint256 newValue
    );
    event NextSelectionBlockUpdated(uint256 oldValue, uint256 newValue);
    event ContractInitialized(
        address indexed accountsContract,
        address indexed nodesContract,
        uint256 blocksBetweenSelection,
        uint256 blocksWithoutProposeThreshold,
        uint256 nextSelectionBlock,
        uint256 initialValidatorsCount
    );
    event ContractUpgraded(
        address indexed newImplementation,
        address indexed upgrader
    );

    error InactiveAccount(address account);
    error NotLocalNode(bytes32 enodeHigh, bytes32 enodeLow);
    error NotElegibleNode(address nodeAddress);
    error NotOperationalNode(address nodeAddress);
    error FewEligibleValidators();
    error InvalidConfigurationValue(string parameter, uint256 value);
    error InvalidValidatorAddress(address validator);
    error DuplicateValidator(address validator);
    error CannotModifyDuringSelection();
    error CannotRemoveOperationalValidator(address validator);

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
        address[] memory initialElegibleValidators,
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

        emit ContractInitialized(
            address(_accountsContract),
            address(_nodesContract),
            _blocksBetweenSelection,
            _blocksWithoutProposeThreshold,
            _nextSelectionBlock,
            initialElegibleValidators.length
        );
    }

    function _initElegibleValidators(
        address[] memory initialElegibleValidators
    ) internal {
        uint256 initialElegibleValidatorsLength = initialElegibleValidators
            .length;
        if (initialElegibleValidatorsLength < MIN_NUMBER_OF_VALIDATORS)
            revert FewEligibleValidators();
        for (uint256 i; i < initialElegibleValidatorsLength; i++) {
            address validator = initialElegibleValidators[i];
            if (validator == address(0))
                revert InvalidValidatorAddress(validator);
            bool added = elegibleValidators.add(validator);
            if (!added) revert DuplicateValidator(validator);
            emit EligibleValidatorAdded(validator);
        }
    }

    function getActiveValidators() external view returns (address[] memory) {
        return operationalValidators.values();
    }

    // usar ou não onlyActiveAdmin?
    // qualquer um pode contribuir com o monitoramento ou apenas as organizações?
    function monitorsValidators() external {
        emit MonitorExecuted();
        address proposer = block.coinbase;
        uint256 blockNumber = block.number;
        if (lastBlockProposedBy[proposer] == blockNumber) {
            return;
        }
        _monitorsValidators(proposer, blockNumber);
        if (_isAtSelectionBlock(blockNumber)) {
            address[] memory selectedValidators = _selectValidators(
                blockNumber
            );
            if (_doesItNeedRemoval(selectedValidators)) {
                _removeOperationalValidators(selectedValidators);
            }
            _updateNextSelectionBlock();
        }
    }

    function _monitorsValidators(
        address proposer,
        uint256 blockNumber
    ) internal {
        lastBlockProposedBy[proposer] = blockNumber;
        emit ValidatorProposalTracked(proposer, blockNumber);
    }

    function _isAtSelectionBlock(
        uint256 blockNumber
    ) internal view returns (bool) {
        return blockNumber == nextSelectionBlock;
    }

    function _selectValidators(
        uint256 blockNumber
    ) internal returns (address[] memory) {
        uint256 numberOfOperationalValidators = operationalValidators.length();
        address[] memory auxArray = new address[](
            numberOfOperationalValidators
        );
        uint256 numberOfSelectedValidators;

        for (uint256 i; i < numberOfOperationalValidators; i++) {
            address candidateValidator = operationalValidators.at(i);
            uint256 lastBlockOfCandidateValidator = lastBlockProposedBy[
                candidateValidator
            ];

            if (
                blockNumber - lastBlockOfCandidateValidator >
                blocksWithoutProposeThreshold
            ) {
                auxArray[numberOfSelectedValidators++] = candidateValidator;
            }
        }

        address[] memory selectedValidators = new address[](
            numberOfSelectedValidators
        );
        for (uint256 i; i < numberOfSelectedValidators; i++) {
            selectedValidators[i] = auxArray[i];
        }

        emit SelectionExecuted();
        return selectedValidators;
    }

    function _doesItNeedRemoval(
        address[] memory selectedValidators
    ) internal view returns (bool) {
        uint256 numberOfSelectedValidators = selectedValidators.length;
        if (numberOfSelectedValidators == 0) {
            return false;
        }

        uint256 numberOfOperationalValidators = operationalValidators.length();
        uint256 numberOfRemainingValidators = numberOfOperationalValidators -
            numberOfSelectedValidators;
        if (numberOfRemainingValidators < MIN_NUMBER_OF_VALIDATORS) {
            return false;
        }

        return true;
    }

    function _removeOperationalValidators(
        address[] memory nonOperationalValidators
    ) internal {
        uint256 numberOfNonOperationalValidators = nonOperationalValidators
            .length;
        for (uint256 i = 0; i < numberOfNonOperationalValidators; i++) {
            address validator = nonOperationalValidators[i];
            operationalValidators.remove(validator);
            delete lastBlockProposedBy[validator];
            emit OperationalValidatorRemoved(validator, address(this));
        }
        emit ValidatorsRemoved(nonOperationalValidators);
    }

    function setBlocksBetweenSelection(
        uint256 _blocksBetweenSelection
    ) external onlyGovernance {
        uint256 oldValue = blocksBetweenSelection;
        blocksBetweenSelection = _blocksBetweenSelection;
        emit BlocksBetweenSelectionUpdated(oldValue, _blocksBetweenSelection);
    }

    function setNextSelectionBlock(
        uint256 _nextSelectionBlock
    ) external onlyGovernance {
        uint256 oldValue = nextSelectionBlock;
        nextSelectionBlock = _nextSelectionBlock;
        emit NextSelectionBlockUpdated(oldValue, _nextSelectionBlock);
    }

    function _updateNextSelectionBlock() internal {
        nextSelectionBlock += blocksBetweenSelection;
    }

    function setBlocksWithoutProposeThreshold(
        uint256 _blocksWithoutProposeThreshold
    ) external onlyGovernance {
        uint256 oldValue = blocksWithoutProposeThreshold;
        blocksWithoutProposeThreshold = _blocksWithoutProposeThreshold;
        emit BlocksWithoutProposeThresholdUpdated(
            oldValue,
            _blocksWithoutProposeThreshold
        );
    }

    function addElegibleValidator(address validator) public onlyGovernance {
        if (validator == address(0)) revert InvalidValidatorAddress(validator);
        bool added = elegibleValidators.add(validator);
        if (!added) revert DuplicateValidator(validator);
        emit EligibleValidatorAdded(validator);
    }

    function addElegibleValidator(
        bytes32 enodeHigh,
        bytes32 enodeLow
    ) external onlyGovernance {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        addElegibleValidator(validator);
    }

    function removeElegibleValidator(address validator) public onlyGovernance {
        if (!elegibleValidators.contains(validator))
            revert NotElegibleNode(validator);
        elegibleValidators.remove(validator);
    }

    function removeElegibleValidator(
        bytes32 enodeHigh,
        bytes32 enodeLow
    ) external onlyGovernance {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        removeElegibleValidator(validator);
    }

    function getEligibleValidators() external view returns (address[] memory) {
        return elegibleValidators.values();
    }

    function getEligibleValidatorsCount() external view returns (uint256) {
        return elegibleValidators.length();
    }

    function getOperationalValidatorsCount() external view returns (uint256) {
        return operationalValidators.length();
    }

    function isEligibleValidator(
        address validator
    ) external view returns (bool) {
        return elegibleValidators.contains(validator);
    }

    function isOperationalValidator(
        address validator
    ) external view returns (bool) {
        return operationalValidators.contains(validator);
    }

    function addEligibleValidatorByEnode(
        bytes32 enodeHigh,
        bytes32 enodeLow
    ) external {
        this.addElegibleValidator(enodeHigh, enodeLow);
    }

    function removeEligibleValidatorByEnode(
        bytes32 enodeHigh,
        bytes32 enodeLow
    ) external {
        this.removeElegibleValidator(enodeHigh, enodeLow);
    }

    function addOperationalValidatorByEnode(
        bytes32 enodeHigh,
        bytes32 enodeLow
    ) external {
        this.addOperationalValidator(enodeHigh, enodeLow);
    }

    function removeOperationalValidatorByEnode(
        bytes32 enodeHigh,
        bytes32 enodeLow
    ) external {
        this.removeOperationalValidator(enodeHigh, enodeLow);
    }

    function addEligibleValidator(address _validator) external {
        addElegibleValidator(_validator);
    }

    function removeEligibleValidator(address _validator) external {
        removeElegibleValidator(_validator);
    }

    function addOperationalValidator(
        bytes32 enodeHigh,
        bytes32 enodeLow
    ) external onlyActiveAdmin onlySameOrganization(enodeHigh, enodeLow) {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        if (!elegibleValidators.contains(validator))
            revert NotElegibleNode(validator);
        bool added = operationalValidators.add(validator);
        if (!added) revert DuplicateValidator(validator);
        lastBlockProposedBy[validator] = block.number;
        emit OperationalValidatorAdded(validator, block.number);
    }

    function addOperationalValidator(
        address validator
    ) external onlyGovernance {
        if (!elegibleValidators.contains(validator))
            revert NotElegibleNode(validator);
        bool added = operationalValidators.add(validator);
        if (!added) revert DuplicateValidator(validator);
        lastBlockProposedBy[validator] = block.number;
        emit OperationalValidatorAdded(validator, block.number);
    }

    function removeOperationalValidator(
        bytes32 enodeHigh,
        bytes32 enodeLow
    ) external onlyActiveAdmin onlySameOrganization(enodeHigh, enodeLow) {
        address validator = _calculateAddress(enodeHigh, enodeLow);
        if (!operationalValidators.contains(validator))
            revert NotOperationalNode(validator);
        operationalValidators.remove(validator);
        delete lastBlockProposedBy[validator];
        emit OperationalValidatorRemoved(validator, _msgSender());
    }

    function removeOperationalValidator(
        address validator
    ) external onlyGovernance {
        if (!operationalValidators.contains(validator))
            revert NotOperationalNode(validator);
        operationalValidators.remove(validator);
        delete lastBlockProposedBy[validator];
        emit OperationalValidatorRemoved(validator, _msgSender());
    }

    function _checkActiveAdmin() internal view {
        if (
            !accountsContract.hasRole(GLOBAL_ADMIN_ROLE, _msgSender()) &&
            !accountsContract.hasRole(LOCAL_ADMIN_ROLE, _msgSender())
        ) {
            revert UnauthorizedAccess(_msgSender());
        }
        if (!accountsContract.isAccountActive(_msgSender())) {
            revert InactiveAccount(_msgSender());
        }
    }

    function _checkSameOrganization(
        bytes32 enodeHigh,
        bytes32 enodeLow
    ) internal view {
        IAccountRulesV2.AccountData memory account = accountsContract
            .getAccount(_msgSender());
        uint256 nodeKey = _calculateKey(enodeHigh, enodeLow);
        (, , , , uint256 orgId, ) = nodesContract.allowedNodes(nodeKey);
        if (account.orgId != orgId) revert NotLocalNode(enodeHigh, enodeLow);
    }

    function _calculateKey(
        bytes32 enodeHigh,
        bytes32 enodeLow
    ) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)));
    }

    function _calculateAddress(
        bytes32 enodeHigh,
        bytes32 enodeLow
    ) internal pure returns (address) {
        return
            address(
                uint160(
                    uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))
                )
            );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyGovernance {}
}
