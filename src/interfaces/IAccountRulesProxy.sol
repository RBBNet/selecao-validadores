// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IAccountRulesProxy {
    function transactionAllowed(
        address sender,
        address target,
        uint256 value,
        uint256 gasPrice,
        uint256 gasLimit,
        bytes calldata payload
    ) external view returns (bool);
}
