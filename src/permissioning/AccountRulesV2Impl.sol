// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "./AccountRulesV2.sol";
import "./Governable.sol";
import "./Organization.sol";
import "./Pagination.sol";

contract AccountRulesV2Impl is AccountRulesV2, Governable, AccessControl {

    using EnumerableSet for EnumerableSet.AddressSet;

    Organization immutable public organizations;
    mapping (address => AccountData) public accounts;
    EnumerableSet.AddressSet private _accountsAddresses;
    mapping (uint => EnumerableSet.AddressSet) _accountsAddressesByOrg;
    mapping (uint => uint) public globalAdminsCount;
    mapping (bytes32 => bool) public validRoles;
    EnumerableSet.AddressSet private _restrictedAccounts;
    EnumerableSet.AddressSet private _restrictedSmartContracts;
    mapping (address => address[]) public restrictedAccountsAllowedTargets;
    mapping (address => address[]) public restrictedSmartContractsAllowedSenders;

    modifier onlyActiveAdmin() {
        if(!hasRole(GLOBAL_ADMIN_ROLE, msg.sender) && !hasRole(LOCAL_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedAccess(msg.sender);
        }
        if(!isAccountActive(msg.sender)) {
            revert InactiveAccount(msg.sender, "The account or the respective organization is not active");
        }
        _;
    }

    modifier validAccount(address account) {
        if(account == address(0)) {
            revert InvalidAccount(account, "Address cannot be 0x0");
        }
        _;
    }

    modifier inexistentAccount(address account) {
        if(accounts[account].account != address(0)) {
            revert DuplicateAccount(account);
        }
        _;
    }

    modifier existentAccount(address account) {
        if(accounts[account].account == address(0)) {
            revert AccountNotFound(account);
        }
        _;
    }

    modifier validRole(bytes32 roleId) {
        if(!validRoles[roleId]) {
            revert InvalidRole(roleId, "The informed role is unknown");
        }
        _;
    }

    modifier notGlobalAdminRole(bytes32 roleId) {
        if(roleId == GLOBAL_ADMIN_ROLE) {
            revert InvalidRole(roleId, "The role cannot be global admin");
        }
        _;
    }

    modifier notGlobalAdminAccount(address account) {
        if(accounts[account].roleId == GLOBAL_ADMIN_ROLE) {
            revert InvalidRole(GLOBAL_ADMIN_ROLE, "The account cannot be global admin");
        }
        _;
    }

    modifier validHash(bytes32 hash) {
        if(hash == 0) {
            revert InvalidHash(hash, "Hash cannot be 0x0");
        }
        _;
    }

    modifier validOrganization(uint orgId) {
        if(!organizations.isOrganizationActive(orgId)) {
            revert InvalidOrganization(orgId, "The informed organization is unknown");
        }
        _;
    }

    modifier sameOrganization(address account) {
        if(accounts[msg.sender].orgId != accounts[account].orgId) {
            revert NotLocalAccount(account);
        }
        _;
    }

    modifier onlyIfMinimumGlobalAdmins(address account) {
        if(_getGlobalAdminCount(accounts[account].orgId) < 2) {
            revert IllegalState("At least 1 global administrator must be active");
        }
        _;
    }

    constructor(Organization orgs, address[] memory accs, AdminProxy adminsProxy) Governable(adminsProxy) {
        if(address(orgs) == address(0)) {
            revert InvalidArgument("Invalid address for Organization management smart contract");
        }
        if(accs.length < 2) {
            revert InvalidArgument("At least 2 accounts must exist");
        }
        organizations = orgs;
        for(uint i = 0; i < accs.length; ++i) {
            // Inclui as contas informadas como administradores globais,
            // utilizando suas posições no array para identificar as organizações.
            address account = accs[i];
            uint orgId = i + 1;
            _addAccount(account, orgId, GLOBAL_ADMIN_ROLE, 0);
        }
        validRoles[GLOBAL_ADMIN_ROLE] = true;
        validRoles[LOCAL_ADMIN_ROLE] = true;
        validRoles[DEPLOYER_ROLE] = true;
        validRoles[USER_ROLE] = true;
    }

    function addLocalAccount(address account, bytes32 roleId, bytes32 dataHash) public
        onlyActiveAdmin validAccount(account) inexistentAccount(account) validRole(roleId) notGlobalAdminRole(roleId) {
        _addAccount(account, accounts[msg.sender].orgId, roleId, dataHash);
    }

    function deleteLocalAccount(address account) public
        onlyActiveAdmin existentAccount(account) sameOrganization(account) notGlobalAdminAccount(account) {
        _deleteAccount(account);
    }

    function updateLocalAccount(address account, bytes32 roleId, bytes32 dataHash) public
        onlyActiveAdmin existentAccount(account) sameOrganization(account) notGlobalAdminAccount(account)
        validRole(roleId) notGlobalAdminRole(roleId) {
        _revertIfInvalidDataHash(roleId, dataHash);
        AccountData storage acc = accounts[account];
        _revokeRole(acc.roleId, account);
        acc.roleId = roleId;
        _grantRole(acc.roleId, account);
        acc.dataHash = dataHash;
        emit AccountUpdated(acc.account, acc.orgId, acc.roleId, dataHash);
    }

    function updateLocalAccountStatus(address account, bool active) public
        onlyActiveAdmin existentAccount(account) sameOrganization(account) notGlobalAdminAccount(account) {
        AccountData storage acc = accounts[account];
        acc.active = active;
        emit AccountStatusUpdated(acc.account, acc.orgId, acc.active);
    }

    function addAccount(address account, uint orgId, bytes32 roleId, bytes32 dataHash) public
        onlyGovernance validAccount(account) inexistentAccount(account) validOrganization(orgId)
        validRole(roleId) {
        _addAccount(account, orgId, roleId, dataHash);
    }

    function _addAccount(address account, uint orgId, bytes32 roleId, bytes32 dataHash) private {
        _revertIfInvalidDataHash(roleId, dataHash);
        AccountData memory newAccount = AccountData(orgId, account, roleId, dataHash, true);
        accounts[account] = newAccount;
        assert(_accountsAddresses.add(account));
        assert(_accountsAddressesByOrg[orgId].add(account));
        _grantRole(roleId, account);
        _incrementGlobalAdminCount(orgId, roleId);
        emit AccountAdded(newAccount.account, newAccount.orgId, newAccount.roleId, newAccount.dataHash);
    }

    function _revertIfInvalidDataHash(bytes32 roleId, bytes32 hash) private pure {
        if(hash == 0 && roleId != GLOBAL_ADMIN_ROLE && roleId != LOCAL_ADMIN_ROLE) {
            revert InvalidHash(hash, "Data hash cannot be 0x0");
        }
    }

    function deleteAccount(address account) public onlyGovernance existentAccount(account) onlyIfMinimumGlobalAdmins(account) {
        _deleteAccount(account);
    }

    function _deleteAccount(address account) private {
        AccountData memory acc = accounts[account];
        _revokeRole(acc.roleId, account);
        delete accounts[account];
        assert(_accountsAddresses.remove(account));
        assert(_accountsAddressesByOrg[acc.orgId].remove(account));
        _decrementGlobalAdminCount(acc.orgId, acc.roleId);
        emit AccountDeleted(account, acc.orgId);
    }

    function _incrementGlobalAdminCount(uint orgId, bytes32 roleId) private {
        if(roleId == GLOBAL_ADMIN_ROLE) {
            globalAdminsCount[orgId] = globalAdminsCount[orgId] + 1;
        }
    }

    function _decrementGlobalAdminCount(uint orgId, bytes32 roleId) private {
        if(roleId == GLOBAL_ADMIN_ROLE) {
            globalAdminsCount[orgId] = globalAdminsCount[orgId] - 1;
        }
    }

    function _getGlobalAdminCount(uint orgId) private view returns (uint) {
        return globalAdminsCount[orgId];
    }

    function setAccountTargetAccess(address account, bool restricted, address[] calldata allowedTargets) public
        onlyActiveAdmin existentAccount(account) sameOrganization(account) notGlobalAdminAccount(account) {
        if(restricted) {
            // Acesso da conta deve ser restrito
            if(allowedTargets.length == 0) {
                revert InvalidArgument("At least one allowed target must be informed");
            }
            _restrictedAccounts.add(account);
            restrictedAccountsAllowedTargets[account] = allowedTargets;
        }
        else {
            // Acesso da conta deve ser liberado
            if(allowedTargets.length > 0) {
                revert InvalidArgument("No allowed target should have been informed");
            }
            _restrictedAccounts.remove(account);
            delete restrictedAccountsAllowedTargets[account];
        }

        emit AccountTargetAccessUpdated(account, restricted, allowedTargets);
    }

    function setSmartContractSenderAccess(address smartContract, bool restricted, address[] calldata allowedSenders) public
        onlyGovernance validAccount(smartContract) {
        if(restricted) {
            // Acesso ao smart contract deve ser restrito
            _restrictedSmartContracts.add(smartContract);
            restrictedSmartContractsAllowedSenders[smartContract] = allowedSenders;
        }
        else {
            // Acesso ao smart contract deve ser liberado
            _restrictedSmartContracts.remove(smartContract);
            delete restrictedSmartContractsAllowedSenders[smartContract];
        }

        emit SmartContractSenderAccessUpdated(smartContract, restricted, allowedSenders);
    }

    function getAccount(address account) public view existentAccount(account) returns (AccountData memory) {
        return accounts[account];
    }

    function isAccountActive(address account) public view returns (bool) {
        AccountData storage acc = accounts[account];
        return acc.active && organizations.isOrganizationActive(acc.orgId);
    }

    function getNumberOfAccounts() public view returns (uint) {
        return _accountsAddresses.length();
    }

    function getNumberOfAccountsByOrg(uint orgId) public view returns (uint) {
        return _accountsAddressesByOrg[orgId].length();
    }

    function getAccounts(uint pageNumber, uint pageSize) public view returns (AccountData[] memory) {
        return _getAccounts(_accountsAddresses, pageNumber, pageSize);
    }

    function getAccountsByOrg(uint orgId, uint pageNumber, uint pageSize) public view returns (AccountData[] memory) {
        return _getAccounts(_accountsAddressesByOrg[orgId], pageNumber, pageSize);
    }

    function _getAccounts(EnumerableSet.AddressSet storage addressSet, uint pageNumber, uint pageSize) private view returns (AccountData[] memory) {
        address[] memory page = Pagination.getAddressPage(addressSet, pageNumber, pageSize);
        AccountData[] memory accs = new AccountData[](page.length);
        for(uint i = 0; i < accs.length; ++i) {
            accs[i] = accounts[page[i]];
        }
        return accs;
    }

    function getAccountTargetAccess(address account) public view returns (bool restricted, address[] memory) {
        return (
            _restrictedAccounts.contains(account),
            restrictedAccountsAllowedTargets[account]
        );
    }

    function getNumberOfRestrictedAccounts() public view returns (uint) {
        return _restrictedAccounts.length();
    }

    function getRestrictedAccounts(uint pageNumber, uint pageSize) external view returns (address[] memory) {
        return Pagination.getAddressPage(_restrictedAccounts, pageNumber, pageSize);
    }

    function getSmartContractSenderAccess(address smartContract) external view returns (bool restricted, address[] memory){
        return (
            _restrictedSmartContracts.contains(smartContract),
            restrictedSmartContractsAllowedSenders[smartContract]
        );
    }

    function getNumberOfRestrictedSmartContracts() external view returns (uint) {
        return _restrictedSmartContracts.length();
    }

    function getRestrictedSmartContracts(uint pageNumber, uint pageSize) external view returns (address[] memory) {
        return Pagination.getAddressPage(_restrictedSmartContracts, pageNumber, pageSize);
    }

    function transactionAllowed(
        address sender,
        address target,
        uint256,
        uint256,
        uint256,
        bytes calldata
    ) external view returns (bool) {
        if(!isAccountActive(sender)) {
            return false;
        }
 
        if(address(0) == target) {
            // Implantação de smart contract
            return hasRole(DEPLOYER_ROLE, sender) || hasRole(LOCAL_ADMIN_ROLE, sender) || hasRole(GLOBAL_ADMIN_ROLE, sender);
        }

        if(_restrictedAccounts.contains(sender)) {
            // Conta tem acesso restrito a alguns targets
            address[] storage allowedTargets = restrictedAccountsAllowedTargets[sender];
            for(uint i = 0; i < allowedTargets.length; ++i) {
                if(target == allowedTargets[i]) {
                    return true;
                }
            }
            return false;
        }

        if(_restrictedSmartContracts.contains(target)) {
            // Chamada a smart contract de acesso restrito
            address[] storage allowedSenders = restrictedSmartContractsAllowedSenders[target];
            for(uint i = 0; i < allowedSenders.length; ++i) {
                if(sender == allowedSenders[i]) {
                    return true;
                }
            }
            return false;
        }

        return true;
    }

}