// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract AdminListMock {
    address[] public allowlist;
    mapping(address => uint256) private indexOf;

    function size() internal view returns (uint256) {
        return allowlist.length;
    }

    function exists(address _account) internal view returns (bool) {
        return indexOf[_account] != 0;
    }

    function add(address _account) internal returns (bool) {
        if (indexOf[_account] == 0) {
            allowlist.push(_account);
            indexOf[_account] = allowlist.length;
            return true;
        }
        return false;
    }

    function addAll(address[] memory accounts, address) internal returns (bool) {
        bool allAdded = true;
        for (uint256 i = 0; i < accounts.length; i++) {
            if (!add(accounts[i])) {
                allAdded = false;
            }
        }
        return allAdded;
    }

    function remove(address _account) internal returns (bool) {
        uint256 index = indexOf[_account];
        if (index > 0 && index <= allowlist.length) {
            if (index != allowlist.length) {
                address lastAccount = allowlist[allowlist.length - 1];
                allowlist[index - 1] = lastAccount;
                indexOf[lastAccount] = index;
            }
            allowlist.pop();
            indexOf[_account] = 0;
            return true;
        }
        return false;
    }
}
