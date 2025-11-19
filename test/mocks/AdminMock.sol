// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IAdminProxy} from "src/interfaces/IAdminProxy.sol";
import {AdminListMock} from "test/mocks/AdminListMock.sol";

contract AdminMock is IAdminProxy, AdminListMock {
    modifier onlyAdmin() {
        require(isAuthorized(msg.sender), "Sender not authorized");
        _;
    }

    modifier notSelf(address _address) {
        require(msg.sender != _address, "Cannot invoke method with own account as parameter");
        _;
    }

    constructor() public {
        add(msg.sender);
    }

    function isAuthorized(address _address) public view returns (bool) {
        return true;
    }

    function addAdmin(address _address) public onlyAdmin returns (bool) {
        return true;
    }

    function removeAdmin(address _address) public onlyAdmin notSelf(_address) returns (bool) {
        return true;
    }

    function getAdmins() public view returns (address[] memory){
        return allowlist;
    }

    function addAdmins(address[] memory accounts) public onlyAdmin returns (bool) {
        return addAll(accounts, msg.sender);
    }
}
