// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IAccountRulesV2} from "src/interfaces/IAccountRulesV2.sol";

bytes32 constant GLOBAL_ADMIN_ROLE = keccak256("GLOBAL_ADMIN_ROLE");
bytes32 constant LOCAL_ADMIN_ROLE = keccak256("LOCAL_ADMIN_ROLE");

contract AccountRulesV2Mock is IAccountRulesV2 {
    mapping(bytes32 => mapping(address => bool)) private _hasRole;
    mapping(address => bool) private _customActive;
    mapping(address => bool) private _hasCustomActive;
    mapping(address => IAccountRulesV2.AccountData) private _customAccounts;
    mapping(address => bool) private _hasCustomAccount;

    function hasRole(bytes32 role, address account) external view returns (bool) {
        return _hasRole[role][account];
    }

    function setRole(bytes32 role, address account, bool value) external {
        _hasRole[role][account] = value;
    }

    function isAccountActive(address account) external view returns (bool) {
        if (_hasCustomActive[account]) return _customActive[account];
        return account != address(0);
    }

    function setAccountActive(address account, bool active) external {
        _customActive[account] = active;
        _hasCustomActive[account] = true;
    }

    function getAccount(address _account) external view returns (IAccountRulesV2.AccountData memory) {
        if (_hasCustomAccount[_account]) return _customAccounts[_account];
        return IAccountRulesV2.AccountData({
            orgId: 1,
            account: _account,
            roleId: GLOBAL_ADMIN_ROLE,
            dataHash: bytes32(0),
            active: _account != address(0)
        });
    }

    function setAccount(address _account, uint256 orgId, bytes32 roleId, bool active) external {
        _customAccounts[_account] = IAccountRulesV2.AccountData({
            orgId: orgId,
            account: _account,
            roleId: roleId,
            dataHash: bytes32(0),
            active: active
        });
        _hasCustomAccount[_account] = true;
    }

    function addLocalAccount(address, bytes32, bytes32) external pure virtual {
        revert("NotSupported: LocalAccount management");
    }

    function deleteLocalAccount(address) external virtual {
        revert("NotSupported: LocalAccount management");
    }

    function updateLocalAccount(address, bytes32, bytes32) external pure {
        revert("NotSupported: LocalAccount management");
    }

    function updateLocalAccountStatus(address, bool) external pure {
        revert("NotSupported: LocalAccount management");
    }

    function setAccountTargetAccess(address, bool, address[] calldata) external pure {
        revert("NotSupported: Target Access");
    }

    function addAccount(address, uint256, bytes32, bytes32) external pure {
        revert("NotSupported: Governance management");
    }

    function deleteAccount(address) external pure {
        revert("NotSupported: Governance management");
    }

    function setSmartContractSenderAccess(address, bool, address[] calldata) external pure {
        revert("NotSupported: Sender Access");
    }
    
    function getNumberOfAccounts() external pure returns (uint256) {
        revert("NotSupported: Read function");
    }

    function getAccounts(uint256, uint256) external pure returns (IAccountRulesV2.AccountData[] memory) {
        revert("NotSupported: Read function");
    }

    function getNumberOfAccountsByOrg(uint256) external pure returns (uint256) {
        revert("NotSupported: Read function");
    }

    function getAccountsByOrg(uint256, uint256, uint256) external pure returns (IAccountRulesV2.AccountData[] memory) {
        revert("NotSupported: Read function");
    }

    function getAccountTargetAccess(address) external pure returns (bool, address[] memory) {
        revert("NotSupported: Read function");
    }

    function getNumberOfRestrictedAccounts() external pure returns (uint256) {
        revert("NotSupported: Read function");
    }

    function getRestrictedAccounts(uint256, uint256) external pure returns (address[] memory) {
        revert("NotSupported: Read function");
    }

    function getSmartContractSenderAccess(address) external pure returns (bool, address[] memory) {
        revert("NotSupported: Read function");
    }

    function getNumberOfRestrictedSmartContracts() external pure returns (uint256) {
        revert("NotSupported: Read function");
    }

    function getRestrictedSmartContracts(uint256, uint256) external pure returns (address[] memory) {
        revert("NotSupported: Read function");
    }

    function transactionAllowed(address, address, uint256, uint256, uint256, bytes calldata)
        external
        pure
        returns (bool)
    {
        revert("NotSupported: Read function");
    }

    function getRoleAdmin(bytes32) external pure returns (bytes32) {
        revert("NotSupported: Read function");
    }

    function grantRole(bytes32, address) external pure {
        revert("NotSupported: Read function");
    }

    function revokeRole(bytes32, address) external pure {
        revert("NotSupported: Read function");
    }

    function renounceRole(bytes32, address) external pure {
        revert("NotSupported: Read function");
    }
}
