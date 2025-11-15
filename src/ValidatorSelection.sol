pragma solidity ^0.8.13;

import "src/IValidatorSelection.sol";

contract ValidatorSelection is IValidatorSelection {
    address[] public elegibleValidators;
    address[] public operationalValidators;
    mapping (address => bool) public isOperational;

    uint16 public blocksBetweenSelection;
    uint16 public blocksWithoutProposeThreshold;

    mapping (address => uint) public lastBlockProposedBy;

    event MonitorExecuted(address indexed executor);
    event SelectionExecuted(address indexed executor);
    event ValidatorRemoved(address indexed removed);

    function monitorsValidators() external {
        address proposer = block.coinbase;
        require(lastBlockProposedBy[proposer] != block.number, "Monitoramento ja executado neste bloco.");
        lastBlockProposedBy[proposer] = block.number;
        isOperational[proposer] = true;
        emit MonitorExecuted(msg.sender);

        if (block.number % blocksBetweenSelection == 0){
            _selectValidators();
        }
    }

    function _selectValidators() internal {
        uint index = 0;
        while (index < operationalValidators.length) {
            address candidateValidator = operationalValidators[index];
            if (block.number - lastBlockProposedBy[candidateValidator] > blocksWithoutProposeThreshold) {
                _removeValidatorByIndex(index);
            } else {
                index++;
            }
        }
        emit SelectionExecuted(msg.sender);
    }

    function _removeValidatorByIndex(uint256 _index) internal {
        address validatorToRemove = operationalValidators[_index];
        isOperational[validatorToRemove] = false;

        uint lastIndex = operationalValidators.length - 1;
        if (_index != lastIndex) {
            operationalValidators[_index] = operationalValidators[lastIndex];
        }
        operationalValidators.pop();
        emit ValidatorRemoved(validatorToRemove);
    }

    function setBlocksBetweenSelection(uint16 _blocksBetweenSelection) external {
        require(_blocksBetweenSelection > 0, "Blocos entre selecao deve ser > 0.");
        blocksBetweenSelection = _blocksBetweenSelection;
    }

    function setBlocksWithoutProposeThreshold(uint16 _blocksWithoutProposeThreshold) external {
        require(_blocksWithoutProposeThreshold > 0, "Limite de blocos sem proposta do validador deve ser > 0.");
        blocksWithoutProposeThreshold = _blocksWithoutProposeThreshold;
    }

    function getActiveValidators() external view returns (address[] memory) {
        return operationalValidators;
    }

    function addOperationalValidator(address _validator) public {
        operationalValidators.push(_validator);
    }
}
