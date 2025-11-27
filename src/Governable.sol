// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IAdminProxy} from "src/interfaces/IAdminProxy.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract Governable is Initializable {
    IAdminProxy public admins;

    error UnauthorizedAccess(address account);
    error InvalidAdminProxyAddress(IAdminProxy invalidAddress);

    modifier onlyGovernance() {
        if (!admins.isAuthorized(msg.sender)) {
            revert UnauthorizedAccess(msg.sender);
        }
        _;
    }

    function __Governable_init(IAdminProxy adminsProxy) internal onlyInitializing {
        if (address(adminsProxy) == address(0)) revert InvalidAdminProxyAddress(adminsProxy);
        admins = adminsProxy;
    }
}
