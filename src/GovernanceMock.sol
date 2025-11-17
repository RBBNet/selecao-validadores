pragma solidity ^0.8.13;

import "src/ValidatorSelection.sol";

contract GovernanceMock {
    ValidatorSelection validatorSelectionContract;

    constructor(address _validatorSelectionAddress){
        validatorSelectionContract = ValidatorSelection(_validatorSelectionAddress);
    }

    function executeSetBlocksBetweenSelection(uint16 _blocksBetweenSelection) public {
        validatorSelectionContract.setBlocksBetweenSelection(_blocksBetweenSelection);
    }

    function executeSetBlocksWithoutProposeThreshold(uint16 _blocksWithoutProposeThreshold) public {
        validatorSelectionContract.setBlocksWithoutProposeThreshold(_blocksWithoutProposeThreshold);
    }

    function executeAddElegibleValidator(address _validator) public {
        validatorSelectionContract.addElegibleValidator(_validator);
    }

    function executeRemoveElegibleValidator(address _validator) public {
        validatorSelectionContract.removeElegibleValidator(_validator);
    }
}
