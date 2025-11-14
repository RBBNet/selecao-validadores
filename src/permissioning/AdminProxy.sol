// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.28;

interface AdminProxy {
    function isAuthorized(address source) external view returns (bool);
}
