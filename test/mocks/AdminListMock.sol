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
        return true;
    }

    function addAll(address[] memory accounts, address _grantor) internal returns (bool) {
        return true;
    }

    function remove(address _account) internal returns (bool) {
        return true;
    }
}
