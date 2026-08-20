// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface AdminProxy {
    function isAuthorized(address source) external view returns (bool);
}
