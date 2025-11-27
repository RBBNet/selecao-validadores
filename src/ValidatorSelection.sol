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
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract ValidatorSelection is IValidatorSelection, Initializable, Governable, OwnableUpgradeable, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IAccountRulesV2 public accountsContract;
    INodeRulesV2 public nodesContract;

    EnumerableSet.AddressSet private elegibleValidators;
    EnumerableSet.AddressSet private operationalValidators;

    uint16 public blocksBetweenSelection;
    uint16 public blocksWithoutProposeThreshold;

    mapping(address => uint256) public lastBlockProposedBy;

    event MonitorExecuted(address indexed executor);
    event SelectionExecuted(address indexed executor);
    event ValidatorRemoved(address indexed removed);

    error InactiveAccount(address account, string message);
    error NotLocalNode(bytes32 enodeHigh, bytes32 enodeLow);
    error InvalidNumberOfBlockBetweenSelection(uint16 numberOfBlocks);
    error InvalidNumberOfBlockWithoutPropose(uint16 numberOfBlocks);
    error NotElegibleNode(address nodeAddress);
    error NotOperationalNode(address nodeAddress);
    error MonitoringAlreadyExecuted();

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

    function monitorsValidators() external {
        address proposer = block.coinbase;
        if (lastBlockProposedBy[proposer] == block.number) revert MonitoringAlreadyExecuted();
        lastBlockProposedBy[proposer] = block.number;
        emit MonitorExecuted(_msgSender());

        if (block.number % blocksBetweenSelection == 0) {
            _selectValidators();
        }
    }

    function _selectValidators() internal {
        uint256 index = 0;
        while (index < operationalValidators.length()) {
            address candidateValidator = operationalValidators.at(index);
            if (block.number - lastBlockProposedBy[candidateValidator] > blocksWithoutProposeThreshold) {
                _removeOperationalValidatorByIndex(index);
            } else {
                index++;
            }
        }
        emit SelectionExecuted(_msgSender());
    }

    function _removeOperationalValidatorByIndex(uint256 _index) internal {
        address validatorToRemove = operationalValidators.at(_index);
        operationalValidators.remove(validatorToRemove);
        emit ValidatorRemoved(validatorToRemove);
    }

    function setBlocksBetweenSelection(uint16 _blocksBetweenSelection) external onlyGovernance {
        if (_blocksBetweenSelection < 0) revert InvalidNumberOfBlockBetweenSelection(_blocksBetweenSelection);
        blocksBetweenSelection = _blocksBetweenSelection;
    }

    function setBlocksWithoutProposeThreshold(uint16 _blocksWithoutProposeThreshold) external onlyGovernance {
        if (_blocksWithoutProposeThreshold < 0) {
            revert InvalidNumberOfBlockWithoutPropose(_blocksWithoutProposeThreshold);
        }
        blocksWithoutProposeThreshold = _blocksWithoutProposeThreshold;
    }

    function getActiveValidators() external view returns (address[] memory) {
        return operationalValidators.values();
    }

    function addElegibleValidator(address _validator) public onlyGovernance {
        elegibleValidators.add(_validator);
    }

    function removeElegibleValidator(address _validator) public onlyGovernance {
        if (elegibleValidators.contains(_validator) == false) revert NotElegibleNode(_validator);
        elegibleValidators.remove(_validator);
    }

    function addOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow) public onlyActiveAdmin {
        address _validator = _calculateAddress(enodeHigh, enodeLow);
        if (elegibleValidators.contains(_validator) == false) revert NotElegibleNode(_validator);
        _revertIfNotSameOrganization(enodeHigh, enodeLow);
        operationalValidators.add(_validator);
    }

    function removeOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow) public onlyActiveAdmin {
        address _validator = _calculateAddress(enodeHigh, enodeLow);
        if (operationalValidators.contains(_validator) == false) revert NotOperationalNode(_validator);
        _revertIfNotSameOrganization(enodeHigh, enodeLow);
        operationalValidators.remove(_validator);
    }

    function _calculateAddress(bytes32 enodeHigh, bytes32 enodeLow) public pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))));
    }

    function _calculateKey(bytes32 enodeHigh, bytes32 enodeLow) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)));
    }

    function _revertIfNotSameOrganization(bytes32 enodeHigh, bytes32 enodeLow) private view {
        IAccountRulesV2.AccountData memory acc = accountsContract.getAccount(_msgSender());
        uint256 nodeKey = _calculateKey(enodeHigh, enodeLow);
        (,,,, uint256 orgId_,) = nodesContract.allowedNodes(nodeKey);
        if (acc.orgId != orgId_) revert NotLocalNode(enodeHigh, enodeLow);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGovernance {}
}
