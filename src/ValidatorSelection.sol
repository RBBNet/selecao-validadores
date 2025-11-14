pragma solidity ^0.8.13;

import "src/IValidatorSelection.sol";

contract ValidatorSelection is IValidatorSelection {
    address[] elegibleValidators;
    address[] operationalValidators;

    function getActiveValidators() external view returns (address[] memory) {
        return operationalValidators;
    }
}
