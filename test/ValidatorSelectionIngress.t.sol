// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, Vm, stdStorage, StdStorage} from "lib/forge-std/src/Test.sol";
import {ValidatorSelectionIngress} from "src/ValidatorSelectionIngress.sol";
import {IValidatorSelectionIngress} from "src/interfaces/IValidatorSelectionIngress.sol";
import {ValidatorSelection} from "src/ValidatorSelection.sol";
import {AdminMock} from "test/mocks/AdminMock.sol";
import {AccountRulesV2Mock} from "test/mocks/AccountRulesV2Mock.sol";
import {NodeRulesV2Mock} from "test/mocks/NodeRulesV2Mock.sol";
import {ValidatorSelectionListMock} from "test/mocks/ValidatorSelectionListMock.sol";

contract ValidatorSelectionIngressTest is Test {
    using stdStorage for StdStorage;

    ValidatorSelectionIngress ingress;
    AdminMock adminMock;
    ValidatorSelectionListMock selectionMock;

    address governance = address(0xABC);
    address proposer = address(0x123);

    Vm.Wallet validator1 = vm.createWallet(1);
    Vm.Wallet validator2 = vm.createWallet(2);
    Vm.Wallet validator3 = vm.createWallet(3);
    Vm.Wallet validator4 = vm.createWallet(4);
    Vm.Wallet validator5 = vm.createWallet(5);

    event ValidatorSelectionContractUpdated(address indexed oldContract, address indexed newContract);
    event AdminContractUpdated(address indexed oldAdmin, address indexed newAdmin);
    event ValidatorSelectionContractRemoved(address indexed oldContract);
    event AdminContractRemoved(address indexed oldAdmin);

    error InvalidAddress();
    error SameAddress(address current);
    error InvalidValidatorSelectionContract(address addr);
    error InvalidAdminContract(address addr);
    error UnauthorizedAccess(address account);

    function setUp() public {
        adminMock = new AdminMock();
        adminMock.addAdmin(governance);

        selectionMock = new ValidatorSelectionListMock();
        selectionMock.setValidators(_validatorList());

        ingress = new ValidatorSelectionIngress(address(adminMock), address(selectionMock));
    }

    function _validatorList() internal view returns (address[] memory) {
        address[] memory validators = new address[](5);
        validators[0] = validator1.addr;
        validators[1] = validator2.addr;
        validators[2] = validator3.addr;
        validators[3] = validator4.addr;
        validators[4] = validator5.addr;
        return validators;
    }

    function test_constructor() public {
        assertEq(ingress.validatorSelectionContract(), address(selectionMock));
        assertEq(address(ingress.admins()), address(adminMock));
    }

    function test_constructor_RevertsIfAdminProxyIsZero() public {
        vm.expectRevert(bytes("Invalid address for Admin management smart contract"));
        new ValidatorSelectionIngress(address(0), address(selectionMock));
    }

    function test_constructor_RevertsIfAdminContractIsInvalid() public {
        bytes memory expectedError = abi.encodeWithSelector(InvalidAdminContract.selector, address(selectionMock));
        vm.expectRevert(expectedError);
        new ValidatorSelectionIngress(address(selectionMock), address(selectionMock));
    }

    function test_constructor_RevertsIfZeroAddressIsAuthorized() public {
        AdminMock newAdminMock = new AdminMock();
        newAdminMock.addAdmin(address(0));

        bytes memory expectedError = abi.encodeWithSelector(InvalidAdminContract.selector, address(newAdminMock));
        vm.expectRevert(expectedError);
        new ValidatorSelectionIngress(address(newAdminMock), address(selectionMock));
    }

    function test_constructor_RevertsIfAdminContractHasNoCode() public {
        address noCode = address(0x9999);
        bytes memory expectedError = abi.encodeWithSelector(InvalidAdminContract.selector, noCode);
        vm.expectRevert(expectedError);
        new ValidatorSelectionIngress(noCode, address(selectionMock));
    }

    function test_constructor_RevertsIfSelectionContractIsZero() public {
        bytes memory expectedError = abi.encodeWithSelector(InvalidAddress.selector);
        vm.expectRevert(expectedError);
        new ValidatorSelectionIngress(address(adminMock), address(0));
    }

    function test_constructor_RevertsIfSelectionContractIsInvalid() public {
        bytes memory expectedError =
            abi.encodeWithSelector(InvalidValidatorSelectionContract.selector, address(adminMock));
        vm.expectRevert(expectedError);
        new ValidatorSelectionIngress(address(adminMock), address(adminMock));
    }

    function test_constructor_RevertsIfSelectionContractReturnsEmptyList() public {
        ValidatorSelectionListMock emptyMock = new ValidatorSelectionListMock();
        bytes memory expectedError =
            abi.encodeWithSelector(InvalidValidatorSelectionContract.selector, address(emptyMock));
        vm.expectRevert(expectedError);
        new ValidatorSelectionIngress(address(adminMock), address(emptyMock));
    }

    function test_getValidators_DelegatesToSelectionContract() public {
        address[] memory validators = ingress.getValidators();
        assertEq(validators, _validatorList());
    }

    function test_getValidators_AnyAccountCanQuery() public {
        vm.prank(vm.createWallet(1234).addr);
        assertEq(ingress.getValidators().length, 5);
    }

    function test_getValidators_FallbackWhenContractIsRemoved() public {
        vm.prank(governance);
        ingress.removeValidatorSelectionContract();

        vm.coinbase(proposer);
        address[] memory validators = ingress.getValidators();
        assertEq(validators.length, 1);
        assertEq(validators[0], proposer);
    }

    function test_getValidators_FallbackWhenCallReverts() public {
        selectionMock.setShouldRevert(true);

        vm.coinbase(proposer);
        address[] memory validators = ingress.getValidators();
        assertEq(validators.length, 1);
        assertEq(validators[0], proposer);
    }

    function test_getValidators_FallbackWhenListIsEmpty() public {
        selectionMock.setValidators(new address[](0));

        vm.coinbase(proposer);
        address[] memory validators = ingress.getValidators();
        assertEq(validators.length, 1);
        assertEq(validators[0], proposer);
    }

    function test_getValidators_FallbackWhenContractHasNoCode() public {
        stdstore.target(address(ingress)).sig(ingress.validatorSelectionContract.selector)
            .checked_write(address(0x9999));
        assertEq(ingress.validatorSelectionContract(), address(0x9999));

        vm.coinbase(proposer);
        address[] memory validators = ingress.getValidators();
        assertEq(validators.length, 1);
        assertEq(validators[0], proposer);
    }

    function test_updateValidatorSelectionContract() public {
        ValidatorSelectionListMock newSelectionMock = new ValidatorSelectionListMock();
        address[] memory newValidators = new address[](1);
        newValidators[0] = validator1.addr;
        newSelectionMock.setValidators(newValidators);

        vm.prank(governance);
        vm.expectEmit(true, true, true, true);
        emit ValidatorSelectionContractUpdated(address(selectionMock), address(newSelectionMock));
        ingress.updateValidatorSelectionContract(address(newSelectionMock));

        assertEq(ingress.validatorSelectionContract(), address(newSelectionMock));
        assertEq(ingress.getValidators(), newValidators);
    }

    function test_updateValidatorSelectionContract_RevertsIfNotGovernance() public {
        address notGovernance = vm.createWallet(1234).addr;
        vm.prank(notGovernance);
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance);
        vm.expectRevert(expectedError, address(ingress));
        ingress.updateValidatorSelectionContract(address(selectionMock));
    }

    function test_updateValidatorSelectionContract_RevertsIfZeroAddress() public {
        vm.prank(governance);
        bytes memory expectedError = abi.encodeWithSelector(InvalidAddress.selector);
        vm.expectRevert(expectedError, address(ingress));
        ingress.updateValidatorSelectionContract(address(0));
    }

    function test_updateValidatorSelectionContract_RevertsIfSameAddress() public {
        vm.prank(governance);
        bytes memory expectedError = abi.encodeWithSelector(SameAddress.selector, address(selectionMock));
        vm.expectRevert(expectedError, address(ingress));
        ingress.updateValidatorSelectionContract(address(selectionMock));
    }

    function test_updateValidatorSelectionContract_RevertsIfEmptyList() public {
        ValidatorSelectionListMock emptyMock = new ValidatorSelectionListMock();
        vm.prank(governance);
        bytes memory expectedError =
            abi.encodeWithSelector(InvalidValidatorSelectionContract.selector, address(emptyMock));
        vm.expectRevert(expectedError, address(ingress));
        ingress.updateValidatorSelectionContract(address(emptyMock));
    }

    function test_updateValidatorSelectionContract_RevertsIfNoGetValidators() public {
        vm.prank(governance);
        bytes memory expectedError =
            abi.encodeWithSelector(InvalidValidatorSelectionContract.selector, address(adminMock));
        vm.expectRevert(expectedError);
        ingress.updateValidatorSelectionContract(address(adminMock));
    }

    function test_removeValidatorSelectionContract() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true);
        emit ValidatorSelectionContractRemoved(address(selectionMock));
        ingress.removeValidatorSelectionContract();

        assertEq(ingress.validatorSelectionContract(), address(0));
    }

    function test_removeValidatorSelectionContract_RevertsIfNotGovernance() public {
        address notGovernance = vm.createWallet(1234).addr;
        vm.prank(notGovernance);
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance);
        vm.expectRevert(expectedError, address(ingress));
        ingress.removeValidatorSelectionContract();
    }

    function test_updateAdminContract() public {
        AdminMock newAdminMock = new AdminMock();

        vm.prank(governance);
        vm.expectEmit(true, true, true, true);
        emit AdminContractUpdated(address(adminMock), address(newAdminMock));
        ingress.updateAdminContract(address(newAdminMock));

        assertEq(address(ingress.admins()), address(newAdminMock));

        vm.prank(governance);
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, governance);
        vm.expectRevert(expectedError, address(ingress));
        ingress.removeValidatorSelectionContract();

        ingress.removeValidatorSelectionContract();
        assertEq(ingress.validatorSelectionContract(), address(0));
    }

    function test_updateAdminContract_RevertsIfNotGovernance() public {
        address notGovernance = vm.createWallet(1234).addr;
        vm.prank(notGovernance);
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance);
        vm.expectRevert(expectedError, address(ingress));
        ingress.updateAdminContract(address(adminMock));
    }

    function test_updateAdminContract_RevertsIfZeroAddress() public {
        vm.prank(governance);
        bytes memory expectedError = abi.encodeWithSelector(InvalidAddress.selector);
        vm.expectRevert(expectedError, address(ingress));
        ingress.updateAdminContract(address(0));
    }

    function test_updateAdminContract_RevertsIfSameAddress() public {
        vm.prank(governance);
        bytes memory expectedError = abi.encodeWithSelector(SameAddress.selector, address(adminMock));
        vm.expectRevert(expectedError, address(ingress));
        ingress.updateAdminContract(address(adminMock));
    }

    function test_updateAdminContract_RevertsIfInvalidContract() public {
        vm.prank(governance);
        bytes memory expectedError = abi.encodeWithSelector(InvalidAdminContract.selector, address(selectionMock));
        vm.expectRevert(expectedError);
        ingress.updateAdminContract(address(selectionMock));
    }

    function test_removeAdminContract() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true);
        emit AdminContractRemoved(address(adminMock));
        ingress.removeAdminContract();

        assertEq(address(ingress.admins()), address(0));

        vm.prank(governance);
        vm.expectRevert();
        ingress.removeValidatorSelectionContract();
    }

    function test_removeAdminContract_RevertsIfNotGovernance() public {
        address notGovernance = vm.createWallet(1234).addr;
        vm.prank(notGovernance);
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance);
        vm.expectRevert(expectedError, address(ingress));
        ingress.removeAdminContract();
    }

    function test_supportsInterface() public {
        assertTrue(ingress.supportsInterface(0x01ffc9a7));
        assertTrue(ingress.supportsInterface(type(IValidatorSelectionIngress).interfaceId));
        assertFalse(ingress.supportsInterface(0xffffffff));
    }

    // ---------------------------------------------------- integração com a Lógica

    function test_integrationWithValidatorSelectionLogic() public {
        ValidatorSelection logic = _deployLogicWithOperationalValidators();

        ValidatorSelectionIngress logicIngress = new ValidatorSelectionIngress(address(adminMock), address(logic));
        assertEq(logicIngress.getValidators(), logic.getValidators());
        assertEq(logicIngress.getValidators().length, 5);

        ValidatorSelection newLogic = _deployLogicWithOperationalValidators();
        vm.prank(governance);
        logicIngress.updateValidatorSelectionContract(address(newLogic));
        assertEq(logicIngress.getValidators(), newLogic.getValidators());
    }

    function _deployLogicWithOperationalValidators() internal returns (ValidatorSelection) {
        ValidatorSelection logic = new ValidatorSelection(
            adminMock, new AccountRulesV2Mock(), new NodeRulesV2Mock(), _validatorList(), 2, 10, 10
        );
        return logic;
    }

    function test_getValidators_FallbackWhenContractIsZero() public {
        vm.prank(governance);
        ingress.removeValidatorSelectionContract();

        address[] memory validators = ingress.getValidators();
        assertEq(validators.length, 1);
        assertEq(validators[0], block.coinbase);
    }

    function test_getValidators_FallbackOnRevert() public {
        selectionMock.setShouldRevert(true);

        address[] memory validators = ingress.getValidators();
        assertEq(validators.length, 1);
        assertEq(validators[0], block.coinbase);
    }

    function test_getValidators_FallbackOnEmptyList() public {
        address[] memory empty;
        selectionMock.setValidators(empty);

        address[] memory validators = ingress.getValidators();
        assertEq(validators.length, 1);
        assertEq(validators[0], block.coinbase);
    }
}
