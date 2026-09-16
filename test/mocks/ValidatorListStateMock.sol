// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IValidatorList} from "src/interfaces/IValidatorList.sol";

contract ValidatorListStateMock is IValidatorList {
    bool public broken;
    bool public empty;

    function setBroken(bool value) external {
        broken = value;
    }

    function setEmpty(bool value) external {
        empty = value;
    }

    // Retorna uma lista válida no momento da validação do ingress; depois pode
    // ser configurado para reverter (broken) ou retornar lista vazia (empty),
    // acionando o mecanismo de fallback do ValidatorSelectionIngress.
    function getValidators() external view returns (address[] memory) {
        if (broken) revert("broken");
        if (empty) return new address[](0);
        address[] memory validators = new address[](1);
        validators[0] = address(0x1);
        return validators;
    }
}
