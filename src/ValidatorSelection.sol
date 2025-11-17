pragma solidity ^0.8.13;

import {IValidatorSelection} from "src/IValidatorSelection.sol";
import {Governable} from "src/Governable.sol";
import {AdminProxy} from "src/AdminProxy.sol";
import {NodeRulesV2Mock} from "src/NodeRulesV2Mock.sol";
import {AccountRulesV2Mock, GLOBAL_ADMIN_ROLE, LOCAL_ADMIN_ROLE} from "src/AccountRulesV2Mock.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ValidatorSelection is IValidatorSelection, Governable {
    using EnumerableSet for EnumerableSet.AddressSet;

    AccountRulesV2Mock public accountsContract;
    NodeRulesV2Mock public nodesContract;

    EnumerableSet.AddressSet private elegibleValidators;
    EnumerableSet.AddressSet private operationalValidators;

    uint16 public blocksBetweenSelection;
    uint16 public blocksWithoutProposeThreshold;

    mapping (address => uint) public lastBlockProposedBy;

    event MonitorExecuted(address indexed executor);
    event SelectionExecuted(address indexed executor);
    event ValidatorRemoved(address indexed removed);

    error InactiveAccount(address account, string message);
    error NotLocalNode(bytes32 enodeHigh, bytes32 enodeLow);

    constructor(AdminProxy adminsProxy, AccountRulesV2Mock _accountsContract, NodeRulesV2Mock _nodesContract) Governable (adminsProxy) {
        accountsContract = _accountsContract;
        nodesContract = _nodesContract;
    }

    modifier onlyActiveAdmin() {
        if(!accountsContract.hasRole(GLOBAL_ADMIN_ROLE, msg.sender) && !accountsContract.hasRole(LOCAL_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedAccess(msg.sender);
        }
        if(!accountsContract.isAccountActive(msg.sender)) {
            revert InactiveAccount(msg.sender, "The account or the respective organization is not active");
        }
        _;
    }

    function monitorsValidators() external {
        address proposer = block.coinbase;
        require(lastBlockProposedBy[proposer] != block.number, "Monitoring already executed in this block.");
        lastBlockProposedBy[proposer] = block.number;
        emit MonitorExecuted(msg.sender);

        if (block.number % blocksBetweenSelection == 0){
            _selectValidators();
        }
    }

    function _selectValidators() internal {
        uint index = 0;
        while (index < operationalValidators.length()) {
            address candidateValidator = operationalValidators.at(index);
            if (block.number - lastBlockProposedBy[candidateValidator] > blocksWithoutProposeThreshold) {
                _removeOperationalValidatorByIndex(index);
            } else {
                index++;
            }
        }
        emit SelectionExecuted(msg.sender);
    }

    function _removeOperationalValidatorByIndex(uint256 _index) internal {
        address validatorToRemove = operationalValidators.at(_index);
        operationalValidators.remove(validatorToRemove);
        emit ValidatorRemoved(validatorToRemove);
    }

    function setBlocksBetweenSelection(uint16 _blocksBetweenSelection) onlyGovernance external {
        require(_blocksBetweenSelection > 0, "Blocks between selection must be > 0.");
        blocksBetweenSelection = _blocksBetweenSelection;
    }

    function setBlocksWithoutProposeThreshold(uint16 _blocksWithoutProposeThreshold) onlyGovernance external {
        require(_blocksWithoutProposeThreshold > 0, "The limit for blocks without a validator proposal must be > 0.");
        blocksWithoutProposeThreshold = _blocksWithoutProposeThreshold;
    }

    function getActiveValidators() external view returns (address[] memory) {
        return operationalValidators.values();
    }

    function addElegibleValidator(address _validator) onlyGovernance public {
        elegibleValidators.add(_validator);
    }

    function removeElegibleValidator(address _validator) onlyGovernance public {
        require(elegibleValidators.contains(_validator) == true, "This node is not eligible");
        elegibleValidators.remove(_validator);
    }

    function addOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow) onlyActiveAdmin public {
        address _validator = _calculateAddress(enodeHigh, enodeLow);
        require(elegibleValidators.contains(_validator) == true, "This node is not eligible");
        _revertIfNotSameOrganization(enodeHigh, enodeLow);
        operationalValidators.add(_validator);
    }

    function removeOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow) onlyActiveAdmin public {
        address _validator = _calculateAddress(enodeHigh, enodeLow);
        require(operationalValidators.contains(_validator) == true, "This node is not operational");
        _revertIfNotSameOrganization(enodeHigh, enodeLow);
        operationalValidators.remove(_validator);
    }

    function _calculateAddress(bytes32 enodeHigh, bytes32 enodeLow) public pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))));
    }

    function _calculateKey(bytes32 enodeHigh, bytes32 enodeLow) private pure returns(uint) {
        return uint(keccak256(abi.encodePacked(enodeHigh, enodeLow)));
    }

    function _revertIfNotSameOrganization(bytes32 enodeHigh, bytes32 enodeLow) private view {
        AccountRulesV2Mock.AccountData memory acc = accountsContract.getAccount(msg.sender);
        uint nodeKey = _calculateKey(enodeHigh, enodeLow);
        (,,,,uint orgId_,) = nodesContract.allowedNodes(nodeKey);
        if(acc.orgId != orgId_) {
            revert NotLocalNode(enodeHigh, enodeLow);
        }
    }
}
