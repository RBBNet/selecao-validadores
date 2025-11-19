pragma solidity ^0.8.13;

interface IValidatorSelection {
    function getActiveValidators() external view returns (address[] memory);
}
