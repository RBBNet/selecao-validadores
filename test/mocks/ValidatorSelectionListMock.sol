// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ValidatorSelectionListMock {
    address[] private validators;
    bool private shouldRevert;

    function setValidators(address[] memory _validators) external {
        validators = _validators;
    }

    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }

    function getValidators() external view returns (address[] memory) {
        require(!shouldRevert, "ValidatorSelectionListMock: forced revert");
        return validators;
    }
}
