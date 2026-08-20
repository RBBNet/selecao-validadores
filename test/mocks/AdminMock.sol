// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AdminProxy} from "permissioning/AdminProxy.sol";
import {AdminListMock} from "test/mocks/AdminListMock.sol";

contract AdminMock is AdminProxy, AdminListMock {
    modifier onlyAdmin() {
        require(isAuthorized(msg.sender), "Sender not authorized");
        _;
    }

    modifier notSelf(address _address) {
        require(msg.sender != _address, "Cannot invoke method with own account as parameter");
        _;
    }

    constructor() {
        add(msg.sender);
    }

    function isAuthorized(address _address) public view returns (bool) {
        return exists(_address);
    }

    function addAdmin(address _address) public onlyAdmin returns (bool) {
        return add(_address);
    }

    function removeAdmin(address _address) public onlyAdmin notSelf(_address) returns (bool) {
        return remove(_address);
    }

    function getAdmins() public view returns (address[] memory) {
        return allowlist;
    }

    function addAdmins(address[] memory accounts) public onlyAdmin returns (bool) {
        return addAll(accounts, msg.sender);
    }
}
