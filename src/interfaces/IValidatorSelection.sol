// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IValidatorSelection {
    function monitorsValidators() external;
    function getActiveValidators() external view returns (address[] memory);
    function getEligibleValidators() external view returns (address[] memory);
    function getEligibleValidatorsCount() external view returns (uint256);
    function getOperationalValidatorsCount() external view returns (uint256);
    function isEligibleValidator(address validator) external view returns (bool);
    function isOperationalValidator(address validator) external view returns (bool);
    
    function setBlocksBetweenSelection(uint256 _blocksBetweenSelection) external;
    function setBlocksWithoutProposeThreshold(uint256 _blocksWithoutProposeThreshold) external;
    function setBatchSize(uint256 _batchSize) external;
    
    function addEligibleValidator(address _validator) external;
    function removeEligibleValidator(address _validator) external;
    function addEligibleValidatorByEnode(bytes32 enodeHigh, bytes32 enodeLow) external;
    function removeEligibleValidatorByEnode(bytes32 enodeHigh, bytes32 enodeLow) external;
    
    function addOperationalValidatorByEnode(bytes32 enodeHigh, bytes32 enodeLow) external;
    function removeOperationalValidatorByEnode(bytes32 enodeHigh, bytes32 enodeLow) external;
    
    function addOperationalValidator(address _validator) external;
    function removeOperationalValidator(address _validator) external;
}

