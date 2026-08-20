// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/ValidatorSelection.sol";

contract GovernanceMock {
    ValidatorSelection validatorSelectionContract;

    constructor(address _validatorSelectionAddress) {
        validatorSelectionContract = ValidatorSelection(_validatorSelectionAddress);
    }

    function executeSetSelectionParameters(uint256 _blocksBetweenSelection, uint256 _blocksWithoutProposeThreshold)
        public
    {
        validatorSelectionContract.setSelectionParameters(_blocksBetweenSelection, _blocksWithoutProposeThreshold);
    }

    function executeAddEligibleValidator(address _validator, bool _activateAsOperational) public {
        validatorSelectionContract.addEligibleValidatorByAddress(_validator, _activateAsOperational);
    }

    function executeRemoveEligibleValidator(address _validator) public {
        validatorSelectionContract.removeEligibleValidatorByAddress(_validator);
    }
}
