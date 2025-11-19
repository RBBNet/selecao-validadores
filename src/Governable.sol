// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.28;

import {IAdminProxy} from "src/interfaces/IAdminProxy.sol";

abstract contract Governable {

    IAdminProxy immutable public admins;

    error UnauthorizedAccess(address account);

    modifier onlyGovernance() {
        if(!admins.isAuthorized(msg.sender)) {
            revert UnauthorizedAccess(msg.sender);
        }
        _;
    }

    constructor(IAdminProxy adminsProxy) {
        require(address(adminsProxy) != address(0), "Invalid address for Admin management smart contract");
        admins = adminsProxy;
   }

}