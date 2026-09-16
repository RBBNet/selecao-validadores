// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IAccountRulesV2} from "src/interfaces/IAccountRulesV2.sol";

contract AccountRulesV2ConfigurableMock is IAccountRulesV2 {
    mapping(bytes32 => mapping(address => bool)) private _hasRole;
    mapping(address => bool) private _active;
    mapping(address => uint256) private _orgId;

    // Setters configuráveis pelos cenários

    function setHasRole(bytes32 role, address account, bool value) external {
        _hasRole[role][account] = value;
    }

    function setAccountActive(address account, bool value) external {
        _active[account] = value;
    }

    function setAccountOrgId(address account, uint256 orgId) external {
        _orgId[account] = orgId;
    }

    // Getters que leem do storage configurado

    function hasRole(bytes32 role, address account) external view returns (bool) {
        return _hasRole[role][account];
    }

    function isAccountActive(address account) external view returns (bool) {
        return _active[account];
    }

    function getAccount(address account) external view returns (IAccountRulesV2.AccountData memory) {
        return IAccountRulesV2.AccountData({
            orgId: _orgId[account],
            account: account,
            roleId: bytes32(0),
            dataHash: bytes32(0),
            active: _active[account]
        });
    }

    // Funções não utilizadas nos testes BDD — rejeitam para sinalizar uso indevido

    function transactionAllowed(address, address, uint256, uint256, uint256, bytes calldata)
        external
        pure
        returns (bool)
    {
        revert("NotSupported: Read function");
    }

    function addLocalAccount(address, bytes32, bytes32) external pure {
        revert("NotSupported: LocalAccount management");
    }

    function deleteLocalAccount(address) external pure {
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