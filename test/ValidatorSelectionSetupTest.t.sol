// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Vm} from "lib/forge-std/src/Test.sol";
import {ValidatorSelection} from "src/ValidatorSelection.sol";
import {IValidatorSelection} from "src/interfaces/IValidatorSelection.sol";
import {AccountRulesV2Mock} from "test/mocks/AccountRulesV2Mock.sol";
import {ValidatorSelectionBaseTest} from "test/ValidatorSelectionBaseTest.t.sol";

contract ValidatorSelectionSetupTest is ValidatorSelectionBaseTest {
    function test_getValidators() public view {
        address[] memory active = validatorSelection.getValidators();
        assertEq(active.length, 5);
    }

    function test_getEligibleValidators() public view {
        address[] memory eligible = validatorSelection.getEligibleValidators();
        assertEq(eligible.length, 5);
        assertEq(eligible[0], validator1.addr);
        assertEq(eligible[1], validator2.addr);
        assertEq(eligible[2], validator3.addr);
        assertEq(eligible[3], validator4.addr);
        assertEq(eligible[4], validator5.addr);
    }

    function test_getEligibleValidators_AnyAccountCanQuery() public {
        vm.prank(vm.createWallet(1234).addr);
        validatorSelection.getEligibleValidators();
    }

    function test_getProtectedValidators() public {
        assertEq(validatorSelection.getProtectedValidators().length, 5);

        Vm.Wallet memory validator6 = vm.createWallet(6);
        Vm.Wallet memory validator7 = vm.createWallet(7);
        vm.startPrank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator6.addr, false);
        validatorSelection.addEligibleValidatorByAddress(validator7.addr, false);
        validatorSelection.addOperationalValidatorByAddress(validator6.addr);
        validatorSelection.addOperationalValidatorByAddress(validator7.addr);
        vm.stopPrank();

        address[] memory added = validatorSelection.getProtectedValidators();
        assertEq(added.length, 7);
        assertEq(added[5], validator6.addr);
        assertEq(added[6], validator7.addr);

        vm.prank(address(governanceMock));
        validatorSelection.removeOperationalValidatorByAddress(validator6.addr);

        added = validatorSelection.getProtectedValidators();
        assertEq(added.length, 6);
        assertEq(added[5], validator7.addr);
    }

    function test_isEligible_isOperational_isProtected() public {
        assertTrue(validatorSelection.isEligible(validator1.addr));
        assertTrue(validatorSelection.isOperational(validator1.addr));
        assertTrue(validatorSelection.isProtected(validator1.addr));

        Vm.Wallet memory notValidator = vm.createWallet(9999);
        assertFalse(validatorSelection.isEligible(notValidator.addr));
        assertFalse(validatorSelection.isOperational(notValidator.addr));
        assertFalse(validatorSelection.isProtected(notValidator.addr));
    }

    function test_constructor_RevertsIfPermissioningContractIsZero() public {
        bytes memory expectedError = abi.encodeWithSelector(InvalidAddress.selector);
        vm.expectRevert(expectedError);
        new ValidatorSelection(
            adminMock,
            AccountRulesV2Mock(address(0)),
            nodeRulesMock,
            _initialEligibleValidators(),
            initialBlocksBetweenSelection,
            initialBlocksWithoutProposeThreshold,
            initialNextSelectionBlock
        );
    }

    function test_constructor_RevertsIfInitialValidatorIsZeroAddress() public {
        address[] memory initialEligibleValidators = _initialEligibleValidators();
        initialEligibleValidators[2] = address(0);

        bytes memory expectedError = abi.encodeWithSelector(InvalidValidatorAddress.selector, address(0));
        vm.expectRevert(expectedError);
        new ValidatorSelection(
            adminMock,
            accountRulesMock,
            nodeRulesMock,
            initialEligibleValidators,
            initialBlocksBetweenSelection,
            initialBlocksWithoutProposeThreshold,
            initialNextSelectionBlock
        );
    }

    function test_constructor_RevertsIfInitialValidatorIsDuplicated() public {
        address[] memory initialEligibleValidators = _initialEligibleValidators();
        initialEligibleValidators[4] = validator1.addr;

        bytes memory expectedError = abi.encodeWithSelector(AlreadyEligibleNode.selector, validator1.addr);
        vm.expectRevert(expectedError);
        new ValidatorSelection(
            adminMock,
            accountRulesMock,
            nodeRulesMock,
            initialEligibleValidators,
            initialBlocksBetweenSelection,
            initialBlocksWithoutProposeThreshold,
            initialNextSelectionBlock
        );
    }

    function test_constructor_RevertsIfBlocksBetweenSelectionLessThanOne() public {
        bytes memory expectedError = abi.encodeWithSelector(InvalidBlocksBetweenSelection.selector);
        vm.expectRevert(expectedError);
        new ValidatorSelection(
            adminMock,
            accountRulesMock,
            nodeRulesMock,
            _initialEligibleValidators(),
            0,
            initialBlocksWithoutProposeThreshold,
            initialNextSelectionBlock
        );
    }

    function test_constructor_RevertsIfThresholdLessThanEligibleValidators() public {
        bytes memory expectedError = abi.encodeWithSelector(InvalidBlocksWithoutProposeThreshold.selector);
        vm.expectRevert(expectedError);
        new ValidatorSelection(
            adminMock,
            accountRulesMock,
            nodeRulesMock,
            _initialEligibleValidators(),
            initialBlocksBetweenSelection,
            4,
            initialNextSelectionBlock
        );
    }

    function test_constructor_RevertsIfFewEligibleValidators() public {
        address[] memory fewValidators = new address[](0);

        bytes memory expectedError = abi.encodeWithSelector(FewEligibleValidators.selector);
        vm.expectRevert(expectedError);
        new ValidatorSelection(
            adminMock,
            accountRulesMock,
            nodeRulesMock,
            fewValidators,
            initialBlocksBetweenSelection,
            initialBlocksWithoutProposeThreshold,
            initialNextSelectionBlock
        );
    }

    function test_supportsInterface() public view {
        assertTrue(validatorSelection.supportsInterface(0x01ffc9a7));
        assertTrue(validatorSelection.supportsInterface(type(IValidatorSelection).interfaceId));
        assertFalse(validatorSelection.supportsInterface(0xffffffff));
    }
}
