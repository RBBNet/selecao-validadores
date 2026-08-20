// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IValidatorSelectionIngress} from "src/interfaces/IValidatorSelectionIngress.sol";
import {IValidatorList} from "src/interfaces/IValidatorList.sol";
import {Governable} from "permissioning/Governable.sol";
import {AdminProxy} from "permissioning/AdminProxy.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract ValidatorSelectionIngress is IValidatorSelectionIngress, Governable {
    address public validatorSelectionContract;

    event ValidatorSelectionContractUpdated(address indexed oldContract, address indexed newContract);
    event AdminContractUpdated(address indexed oldAdmin, address indexed newAdmin);
    event ValidatorSelectionContractRemoved(address indexed oldContract);
    event AdminContractRemoved(address indexed oldAdmin);

    error InvalidAddress();
    error SameAddress(address current);
    error InvalidValidatorSelectionContract(address addr);
    error InvalidAdminContract(address addr);

    constructor(address _adminProxy, address _validatorSelectionContract) Governable(AdminProxy(_adminProxy)) {
        _validateAdminContract(_adminProxy);
        if (_validatorSelectionContract == address(0)) revert InvalidAddress();
        _validateValidatorSelectionContract(_validatorSelectionContract);
        validatorSelectionContract = _validatorSelectionContract;
    }

    function getValidators() external view returns (address[] memory) {
        if (validatorSelectionContract.code.length > 0) {
            try IValidatorList(validatorSelectionContract).getValidators() returns (address[] memory validators) {
                if (validators.length >= 1) {
                    return validators;
                }
            } catch {}
        }
        address[] memory fallbackValidators = new address[](1);
        fallbackValidators[0] = block.coinbase;
        return fallbackValidators;
    }

    function updateValidatorSelectionContract(address _newContract) external onlyGovernance {
        if (_newContract == address(0)) revert InvalidAddress();
        if (_newContract == validatorSelectionContract) revert SameAddress(_newContract);
        _validateValidatorSelectionContract(_newContract);
        address oldContract = validatorSelectionContract;
        validatorSelectionContract = _newContract;
        emit ValidatorSelectionContractUpdated(oldContract, _newContract);
    }

    function removeValidatorSelectionContract() external onlyGovernance {
        address oldContract = validatorSelectionContract;
        validatorSelectionContract = address(0);
        emit ValidatorSelectionContractRemoved(oldContract);
    }

    function updateAdminContract(address _newAdmin) external onlyGovernance {
        if (_newAdmin == address(0)) revert InvalidAddress();
        if (_newAdmin == address(admins)) revert SameAddress(_newAdmin);
        _validateAdminContract(_newAdmin);
        address oldAdmin = address(admins);
        admins = AdminProxy(_newAdmin);
        emit AdminContractUpdated(oldAdmin, _newAdmin);
    }

    function removeAdminContract() external onlyGovernance {
        address oldAdmin = address(admins);
        admins = AdminProxy(address(0));
        emit AdminContractRemoved(oldAdmin);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IValidatorSelectionIngress).interfaceId;
    }

    function _validateAdminContract(address adminContract) internal view {
        if (adminContract.code.length == 0) revert InvalidAdminContract(adminContract);
        try AdminProxy(adminContract).isAuthorized(address(0)) returns (bool authorized) {
            if (authorized) revert InvalidAdminContract(adminContract);
        } catch {
            revert InvalidAdminContract(adminContract);
        }
    }

    function _validateValidatorSelectionContract(address selectionContract) internal view {
        if (selectionContract.code.length == 0) revert InvalidValidatorSelectionContract(selectionContract);
        try IValidatorList(selectionContract).getValidators() returns (address[] memory validators) {
            if (validators.length < 1) revert InvalidValidatorSelectionContract(selectionContract);
        } catch {
            revert InvalidValidatorSelectionContract(selectionContract);
        }
    }
}
