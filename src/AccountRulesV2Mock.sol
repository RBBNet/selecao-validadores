// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.28;

bytes32 constant GLOBAL_ADMIN_ROLE = keccak256("GLOBAL_ADMIN_ROLE");
bytes32 constant LOCAL_ADMIN_ROLE = keccak256("LOCAL_ADMIN_ROLE");

contract AccountRulesV2Mock {
    struct AccountData {
        uint orgId;
        address account;
        bytes32 roleId;
        bytes32 dataHash;
        bool active;
    }

    function hasRole(bytes32 role, address account) external view returns (bool){
        return true;
    }

    function isAccountActive(address account) external view returns (bool){
        return true;
    }
    
    function getAccount(address _account) external view returns (AccountData memory){
        AccountData memory data = AccountData({orgId: 1, account: _account, roleId: GLOBAL_ADMIN_ROLE, dataHash: bytes32(0), active: true});
        return data;
    }
}