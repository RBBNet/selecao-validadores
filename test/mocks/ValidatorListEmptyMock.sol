// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IValidatorList} from "src/interfaces/IValidatorList.sol";

contract ValidatorListEmptyMock is IValidatorList {
    function getValidators() external view returns (address[] memory) {
        return new address[](0);
    }
}
