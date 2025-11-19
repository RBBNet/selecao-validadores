// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IAccountRulesV2} from "src/interfaces/IAccountRulesV2.sol";

bytes32 constant GLOBAL_ADMIN_ROLE = keccak256("GLOBAL_ADMIN_ROLE");
bytes32 constant LOCAL_ADMIN_ROLE = keccak256("LOCAL_ADMIN_ROLE");

contract AccountRulesV2Mock is IAccountRulesV2 {
    function hasRole(bytes32 role, address account) external view returns (bool) {
        return true;
    }

    function isAccountActive(address account) external view returns (bool) {
        return true;
    }

    function getAccount(address _account) external view returns (IAccountRulesV2.AccountData memory) {
        IAccountRulesV2.AccountData memory data = IAccountRulesV2.AccountData({
            orgId: 1,
            account: _account,
            roleId: GLOBAL_ADMIN_ROLE,
            dataHash: bytes32(0),
            active: true
        });
        return data;
    }

    function addLocalAccount(address account, bytes32 roleId, bytes32 dataHash) external virtual {
        revert("NotSupported: LocalAccount management");
    }

    function deleteLocalAccount(address account) external virtual {
        revert("NotSupported: LocalAccount management");
    }

    function updateLocalAccount(address account, bytes32 roleId, bytes32 dataHash) external {
        revert("NotSupported: LocalAccount management");
    }

    function updateLocalAccountStatus(address account, bool active) external {
        revert("NotSupported: LocalAccount management");
    }

    function setAccountTargetAccess(address account, bool restricted, address[] calldata allowedTargets) external {
        revert("NotSupported: Target Access");
    }

    function addAccount(address account, uint256 orgId, bytes32 roleId, bytes32 dataHash) external {
        revert("NotSupported: Governance management");
    }

    function deleteAccount(address account) external {
        revert("NotSupported: Governance management");
    }

    function setSmartContractSenderAccess(address smartContract, bool restricted, address[] calldata allowedSenders)
        external
    {
        revert("NotSupported: Sender Access");
    }

    function getNumberOfAccounts() external view returns (uint256) {
        revert("NotSupported: Read function");
    }

    function getAccounts(uint256 pageNumber, uint256 pageSize)
        external
        view
        returns (IAccountRulesV2.AccountData[] memory)
    {
        revert("NotSupported: Read function");
    }

    function getNumberOfAccountsByOrg(uint256 orgId) external view returns (uint256) {
        revert("NotSupported: Read function");
    }

    function getAccountsByOrg(uint256 orgId, uint256 pageNumber, uint256 pageSize)
        external
        view
        returns (IAccountRulesV2.AccountData[] memory)
    {
        revert("NotSupported: Read function");
    }

    function getAccountTargetAccess(address account) external view returns (bool restricted, address[] memory) {
        revert("NotSupported: Read function");
    }

    function getNumberOfRestrictedAccounts() external view returns (uint256) {
        revert("NotSupported: Read function");
    }

    function getRestrictedAccounts(uint256 pageNumber, uint256 pageSize) external view returns (address[] memory) {
        revert("NotSupported: Read function");
    }

    function getSmartContractSenderAccess(address smartContract)
        external
        view
        returns (bool restricted, address[] memory)
    {
        revert("NotSupported: Read function");
    }

    function getNumberOfRestrictedSmartContracts() external view returns (uint256) {
        revert("NotSupported: Read function");
    }

    function getRestrictedSmartContracts(uint256 pageNumber, uint256 pageSize)
        external
        view
        returns (address[] memory)
    {
        revert("NotSupported: Read function");
    }

    function transactionAllowed(
        address sender,
        address target,
        uint256 value,
        uint256 gasPrice,
        uint256 gasLimit,
        bytes calldata payload
    ) external view returns (bool) {
        revert("NotSupported: Read function");
    }

    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        revert("NotSupported: Read function");
    }

    function grantRole(bytes32 role, address account) external {
        revert("NotSupported: Read function");
    }

    function revokeRole(bytes32 role, address account) external {
        revert("NotSupported: Read function");
    }

    function renounceRole(bytes32 role, address callerConfirmation) external {
        revert("NotSupported: Read function");
    }
}
