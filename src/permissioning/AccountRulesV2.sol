// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./AccountRulesProxy.sol";

bytes32 constant GLOBAL_ADMIN_ROLE = keccak256("GLOBAL_ADMIN_ROLE");
bytes32 constant LOCAL_ADMIN_ROLE = keccak256("LOCAL_ADMIN_ROLE");
bytes32 constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
bytes32 constant USER_ROLE = keccak256("USER_ROLE");

interface AccountRulesV2 is AccountRulesProxy, IAccessControl {

    struct AccountData {
        uint orgId;
        address account;
        bytes32 roleId;
        bytes32 dataHash;
        bool active;
    }

    event AccountAdded(address indexed account, uint indexed orgId, bytes32 roleId, bytes32 dataHash);
    event AccountDeleted(address indexed account, uint indexed orgId);
    event AccountUpdated(address indexed account, uint indexed orgId, bytes32 roleId, bytes32 dataHash);
    event AccountStatusUpdated(address indexed account, uint indexed orgId, bool active);
    event AccountTargetAccessUpdated(address indexed account, bool indexed restricted, address[] allowedTargets);
    event SmartContractSenderAccessUpdated(address indexed smartContract, bool indexed restricted, address[] allowedSenders);

    error InvalidArgument(string message);
    error InactiveAccount(address account, string message);
    error InvalidAccount(address account, string message);
    error DuplicateAccount(address account);
    error AccountNotFound(address account);
    error NotLocalAccount(address account);
    error InvalidOrganization(uint orgId, string message);
    error InvalidRole(bytes32 roleId, string message);
    error InvalidHash(bytes32 hash, string message);
    error IllegalState(string message);

    // Funções disponíveis apenas para administradores (globais e locais)
    function addLocalAccount(address account, bytes32 roleId, bytes32 dataHash) external;
    function deleteLocalAccount(address account) external;
    function updateLocalAccount(address account, bytes32 roleId, bytes32 dataHash) external;
    function updateLocalAccountStatus(address account, bool active) external;
    function setAccountTargetAccess(address account, bool restricted, address[] calldata allowedTargets) external;

    // Funções disponíveis apenas para a governança
    function addAccount(address account, uint orgId, bytes32 roleId, bytes32 dataHash) external;
    function deleteAccount(address account) external;
    function setSmartContractSenderAccess(address smartContract, bool restricted, address[] calldata allowedSenders) external;

    // Funções disponíveis publicamente
    function isAccountActive(address account) external view returns (bool);
    function getAccount(address account) external view returns (AccountData memory);

    function getNumberOfAccounts() external view returns (uint);
    function getAccounts(uint pageNumber, uint pageSize) external view returns (AccountData[] memory);
    function getNumberOfAccountsByOrg(uint orgId) external view returns (uint);
    function getAccountsByOrg(uint orgId, uint pageNumber, uint pageSize) external view returns (AccountData[] memory);

    function getAccountTargetAccess(address account) external view returns (bool restricted, address[] memory);
    function getNumberOfRestrictedAccounts() external view returns (uint);
    function getRestrictedAccounts(uint pageNumber, uint pageSize) external view returns (address[] memory);

    function getSmartContractSenderAccess(address smartContract) external view returns (bool restricted, address[] memory);
    function getNumberOfRestrictedSmartContracts() external view returns (uint);
    function getRestrictedSmartContracts(uint pageNumber, uint pageSize) external view returns (address[] memory);

}