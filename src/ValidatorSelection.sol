pragma solidity ^0.8.13;

import "src/IValidatorSelection.sol";
import "src/permissioning/Governable.sol";
import "src/permissioning/AdminProxy.sol";
import "src/permissioning/NodeRulesV2Impl.sol";

contract ValidatorSelection is IValidatorSelection {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private elegibleValidators;
    EnumerableSet.AddressSet private operationalValidators;

    uint16 public blocksBetweenSelection;
    uint16 public blocksWithoutProposeThreshold;

    mapping (address => uint) public lastBlockProposedBy;

    event MonitorExecuted(address indexed executor);
    event SelectionExecuted(address indexed executor);
    event ValidatorRemoved(address indexed removed);

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

    function setBlocksBetweenSelection(uint16 _blocksBetweenSelection) external {
        require(_blocksBetweenSelection > 0, "Blocks between selection must be > 0.");
        blocksBetweenSelection = _blocksBetweenSelection;
    }

    function setBlocksWithoutProposeThreshold(uint16 _blocksWithoutProposeThreshold) external {
        require(_blocksWithoutProposeThreshold > 0, "The limit for blocks without a validator proposal must be > 0.");
        blocksWithoutProposeThreshold = _blocksWithoutProposeThreshold;
    }

    function getActiveValidators() external view returns (address[] memory) {
        return operationalValidators.values();
    }

    function addOperationalValidator(address _validator) public {
        require(elegibleValidators.contains(_validator) == true, "This node is not eligible");
        operationalValidators.add(_validator);
    }

    function addElegibleValidator(address _validator) public {
        elegibleValidators.add(_validator);
    }

    function removeOperationalValidator(address _validator) public {
        require(operationalValidators.contains(_validator) == true, "This node is not operational");
        operationalValidators.remove(_validator);
    }

    function removeElegibleValidator(address _validator) public {
        require(elegibleValidators.contains(_validator) == true, "This node is not eligible");
        elegibleValidators.remove(_validator);
    }
}
