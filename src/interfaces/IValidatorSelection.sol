// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IValidatorSelection {
    function monitorsValidators() external;
    function setBlocksBetweenSelection(uint256 _blocksBetweenSelection) external;
    function setBlocksWithoutProposeThreshold(uint256 _blocksWithoutProposeThreshold) external;
    function getActiveValidators() external view returns (address[] memory);
    function addElegibleValidator(address _validator) external;
    function removeElegibleValidator(address _validator) external;
    function addOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow) external;
    function removeOperationalValidator(bytes32 enodeHigh, bytes32 enodeLow) external;
}
