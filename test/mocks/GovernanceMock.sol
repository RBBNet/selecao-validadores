// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/ValidatorSelection.sol";

contract GovernanceMock {
    ValidatorSelection validatorSelectionContract;

    constructor(address _validatorSelectionAddress) {
        validatorSelectionContract = ValidatorSelection(_validatorSelectionAddress);
    }

    function executeSetBlocksBetweenSelection(uint256 _blocksBetweenSelection) public {
        validatorSelectionContract.setBlocksBetweenSelection(_blocksBetweenSelection);
    }

    function executeSetBlocksWithoutProposeThreshold(uint256 _blocksWithoutProposeThreshold) public {
        validatorSelectionContract.setBlocksWithoutProposeThreshold(_blocksWithoutProposeThreshold);
    }

    function executeAddEligibleValidator(address _validator) public {
        validatorSelectionContract.addEligibleValidator(_validator);
    }

    function executeAddEligibleValidatorByEnode(bytes32 enodeHigh, bytes32 enodeLow) public {
        validatorSelectionContract.addEligibleValidatorByEnode(enodeHigh, enodeLow);
    }

    function executeRemoveEligibleValidator(address _validator) public {
        validatorSelectionContract.removeEligibleValidator(_validator);
    }

    function executeAddOperationalValidatorByEnode(bytes32 enodeHigh, bytes32 enodeLow) public {
        validatorSelectionContract.addOperationalValidatorByEnode(enodeHigh, enodeLow);
    }

    function executeRemoveOperationalValidatorByEnode(bytes32 enodeHigh, bytes32 enodeLow) public {
        validatorSelectionContract.removeOperationalValidatorByEnode(enodeHigh, enodeLow);
    }

    function executeRemoveEligibleValidatorByEnode(bytes32 enodeHigh, bytes32 enodeLow) public {
        validatorSelectionContract.removeEligibleValidatorByEnode(enodeHigh, enodeLow);
    }
}
