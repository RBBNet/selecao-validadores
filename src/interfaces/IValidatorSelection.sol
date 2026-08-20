// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

enum OperationMode {
    Manual,
    Automatic
}

interface IValidatorSelection {
    function executeMonitoring() external;
    function setOperationMode(OperationMode newMode) external;
    function setSelectionParameters(uint256 _blocksBetweenSelection, uint256 _blocksWithoutProposeThreshold) external;
    function getValidators() external view returns (address[] memory);
    function getEligibleValidators() external view returns (address[] memory);
    function getProtectedValidators() external view returns (address[] memory);
    function isEligible(address validator) external view returns (bool);
    function isOperational(address validator) external view returns (bool);
    function isProtected(address validator) external view returns (bool);
    function addEligibleValidatorByAddress(address _validator, bool activateAsOperational) external;
    function addEligibleValidator(bytes32 enodeHigh, bytes32 enodeLow, bool activateAsOperational) external;
    function removeEligibleValidatorByAddress(address _validator) external;
    function removeEligibleValidator(bytes32 enodeHigh, bytes32 enodeLow) external;
    function addOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow) external;
    function addOperationalValidatorByAddress(address _validator) external;
    function removeOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow) external;
    function removeOperationalValidatorByAdmin(bytes32 enodeHigh, bytes32 enodeLow) external;
    function removeOperationalValidatorByAddress(address _validator) external;
    function updateAdminContract(address _newAdmin) external;
    function updateAccountsContract(address _newAccountsContract) external;
    function updateNodesContract(address _newNodesContract) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
