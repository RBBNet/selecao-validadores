// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;
interface IValidatorSelectionIngress {
    function getValidators() external view returns (address[] memory);
    function updateValidatorSelectionContract(address newContract) external;
    function updateAdminContract(address newAdmin) external;
    function removeValidatorSelectionContract() external;
    function removeAdminContract() external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
