// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.28;

interface IAdmin {
    function isAuthorized(address _address) external view returns (bool);
    function getAdmins() external view returns (address[] memory);

    function addAdmin(address _address) external returns (bool);
    function removeAdmin(address _address) external returns (bool);
    function addAdmins(address[] memory accounts) external returns (bool);

    event AdminAdded(bool result, address indexed adminAddress, address indexed by, uint256 timestamp, string message);
    event AdminRemoved(bool removed, address indexed adminAddress, address indexed by, uint256 timestamp);
}