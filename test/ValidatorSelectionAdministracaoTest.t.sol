// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Vm} from "lib/forge-std/src/Test.sol";
import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";
import {LOCAL_ADMIN_ROLE} from "src/interfaces/IAccountRulesV2.sol";
import {ValidatorSelectionBaseTest} from "test/ValidatorSelectionBaseTest.t.sol";

contract ValidatorSelectionAdministracaoTest is ValidatorSelectionBaseTest {
    Vm.Wallet validator6 = vm.createWallet(6);
    Vm.Wallet validator7 = vm.createWallet(7);

    function _createEnodeValidator() internal pure returns (bytes32 enodeHigh, bytes32 enodeLow, address validator) {
        enodeHigh = bytes32(uint256(1));
        enodeLow = bytes32(uint256(2));
        validator = address(uint160(uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))));
    }

    function test_addOperationalValidator() public {
        vm.startPrank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator6.addr, false);
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorAdded(validator6.addr);
        validatorSelection.addOperationalValidatorByAddress(validator6.addr);
        vm.stopPrank();

        address[] memory active = validatorSelection.getValidators();
        assertEq(active.length, 6);
        assertEq(active[5], validator6.addr);

        address[] memory added = validatorSelection.getProtectedValidators();
        assertEq(added.length, 6);
        assertEq(added[5], validator6.addr);
    }

    function test_addOperationalValidator_RevertsIfNotEligible() public {
        Vm.Wallet memory notEligible = vm.createWallet(1234);
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(NotEligibleNode.selector, notEligible.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.addOperationalValidatorByAddress(notEligible.addr);
    }

    function test_addOperationalValidator_RevertsIfZeroAddress() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(NotEligibleNode.selector, address(0));
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.addOperationalValidatorByAddress(address(0));
    }

    function test_addOperationalValidator_RevertsIfAlreadyOperational() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(AlreadyOperationalNode.selector, validator1.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.addOperationalValidatorByAddress(validator1.addr);
    }

    function test_addOperationalValidator_RevertsIfNotGovernance() public {
        Vm.Wallet memory notGovernance = vm.createWallet(1234);
        vm.prank(notGovernance.addr);
        _expectRevertUnauthorized(notGovernance.addr);
        validatorSelection.addOperationalValidatorByAddress(validator1.addr);
    }

    function test_addOperationalValidator_ByAdminOfSameOrganization() public {
        (bytes32 enodeHigh, bytes32 enodeLow, address validator) = _createEnodeValidator();

        vm.prank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator, false);

        _setSenderAsAdmin(1);
        _registerNode(enodeHigh, enodeLow, INodeRulesV2.NodeType.Validator, 1, true);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorAdded(validator);
        validatorSelection.addOperationalValidator(enodeHigh, enodeLow);

        address[] memory active = validatorSelection.getValidators();
        assertEq(active.length, 6);
        assertEq(active[5], validator);
    }

    function test_addOperationalValidator_ByGovernanceOfAnyOrganization() public {
        (bytes32 enodeHigh, bytes32 enodeLow, address validator) = _createEnodeValidator();

        vm.startPrank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator, false);
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorAdded(validator);
        validatorSelection.addOperationalValidator(enodeHigh, enodeLow);
        vm.stopPrank();

        address[] memory active = validatorSelection.getValidators();
        assertEq(active.length, 6);
        assertEq(active[5], validator);
    }

    function test_addOperationalValidator_RevertsIfAdminOfDifferentOrganization() public {
        (bytes32 enodeHigh, bytes32 enodeLow, address validator) = _createEnodeValidator();

        vm.prank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator, false);

        _setSenderAsAdmin(1);
        _registerNode(enodeHigh, enodeLow, INodeRulesV2.NodeType.Validator, 2, true);

        vm.prank(sender);
        bytes memory expectedError = abi.encodeWithSelector(NotLocalNode.selector, enodeHigh, enodeLow);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.addOperationalValidator(enodeHigh, enodeLow);
    }

    function test_addOperationalValidator_RevertsIfNotAdminNorGovernance() public {
        (bytes32 enodeHigh, bytes32 enodeLow,) = _createEnodeValidator();

        vm.prank(sender);
        _expectRevertUnauthorized(sender);
        validatorSelection.addOperationalValidator(enodeHigh, enodeLow);
    }

    function test_addOperationalValidator_RevertsIfAdminIsInactive() public {
        (bytes32 enodeHigh, bytes32 enodeLow,) = _createEnodeValidator();

        accountRulesMock.setRole(LOCAL_ADMIN_ROLE, sender, true);
        accountRulesMock.setAccountActive(sender, false);

        vm.prank(sender);
        bytes memory expectedError = abi.encodeWithSelector(InactiveAccount.selector, sender);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.addOperationalValidator(enodeHigh, enodeLow);
    }

    function test_removeOperationalValidator() public {
        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorManuallyRemoved(validator1.addr);
        validatorSelection.removeOperationalValidatorByAddress(validator1.addr);

        address[] memory active = validatorSelection.getValidators();
        assertEq(active.length, 4);
        assertEq(validatorSelection.getProtectedValidators().length, 4);
    }

    function test_removeOperationalValidator_RevertsIfNotOperational() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(NotOperationalNode.selector, validator6.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.removeOperationalValidatorByAddress(validator6.addr);
    }

    function test_removeOperationalValidator_RevertsIfLastOperationalValidator() public {
        vm.startPrank(address(governanceMock));
        validatorSelection.removeOperationalValidatorByAddress(validator2.addr);
        validatorSelection.removeOperationalValidatorByAddress(validator3.addr);
        validatorSelection.removeOperationalValidatorByAddress(validator4.addr);
        validatorSelection.removeOperationalValidatorByAddress(validator5.addr);

        bytes memory expectedError = abi.encodeWithSelector(FewOperationalValidators.selector);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.removeOperationalValidatorByAddress(validator1.addr);
        vm.stopPrank();
    }

    function test_removeOperationalValidator_RevertsIfNotGovernance() public {
        Vm.Wallet memory notGovernance = vm.createWallet(1234);
        vm.prank(notGovernance.addr);
        _expectRevertUnauthorized(notGovernance.addr);
        validatorSelection.removeOperationalValidatorByAddress(validator1.addr);
    }

    function test_removeOperationalValidator_ByAdminOfSameOrganization() public {
        (bytes32 enodeHigh, bytes32 enodeLow, address validator) = _createEnodeValidator();

        _setSenderAsAdmin(1);
        _registerNode(enodeHigh, enodeLow, INodeRulesV2.NodeType.Validator, 1, true);

        vm.startPrank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator, false);
        validatorSelection.addOperationalValidatorByAddress(validator);
        validatorSelection.removeOperationalValidatorByAddress(validator5.addr);
        vm.stopPrank();
        assertEq(validatorSelection.getValidators().length, 5);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorManuallyRemoved(validator);
        validatorSelection.removeOperationalValidatorByAdmin(enodeHigh, enodeLow);

        address[] memory active = validatorSelection.getValidators();
        assertEq(active.length, 4);
        for (uint256 i; i < active.length; i++) {
            assertNotEq(active[i], validator);
        }
    }

    function test_removeOperationalValidator_ByAdmin_RevertsIfBelowMinimum() public {
        (bytes32 enodeHigh, bytes32 enodeLow, address validator) = _createEnodeValidator();

        _setSenderAsAdmin(1);
        _registerNode(enodeHigh, enodeLow, INodeRulesV2.NodeType.Validator, 1, true);

        vm.startPrank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator, false);
        validatorSelection.addOperationalValidatorByAddress(validator);
        validatorSelection.removeOperationalValidatorByAddress(validator2.addr);
        validatorSelection.removeOperationalValidatorByAddress(validator3.addr);
        vm.stopPrank();
        assertEq(validatorSelection.getValidators().length, 4);

        vm.prank(sender);
        bytes memory expectedError = abi.encodeWithSelector(FewOperationalValidators.selector);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.removeOperationalValidatorByAdmin(enodeHigh, enodeLow);
    }

    function test_removeOperationalValidator_ByAdmin_RevertsIfNotSameOrg() public {
        (bytes32 enodeHigh, bytes32 enodeLow, address validator) = _createEnodeValidator();

        _setSenderAsAdmin(1);
        _registerNode(enodeHigh, enodeLow, INodeRulesV2.NodeType.Validator, 2, true);

        vm.startPrank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator, false);
        validatorSelection.addOperationalValidatorByAddress(validator);
        vm.stopPrank();

        vm.prank(sender);
        bytes memory expectedError = abi.encodeWithSelector(NotLocalNode.selector, enodeHigh, enodeLow);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.removeOperationalValidatorByAdmin(enodeHigh, enodeLow);
    }

    function test_removeOperationalValidator_ByAdmin_RevertsIfNotAdmin() public {
        (bytes32 enodeHigh, bytes32 enodeLow,) = _createEnodeValidator();

        vm.prank(sender);
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, sender);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.removeOperationalValidatorByAdmin(enodeHigh, enodeLow);
    }

    function test_removeOperationalValidator_ByGovernanceViaEnode() public {
        (bytes32 enodeHigh, bytes32 enodeLow, address validator) = _createEnodeValidator();

        vm.startPrank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator, false);
        validatorSelection.addOperationalValidatorByAddress(validator);

        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorManuallyRemoved(validator);
        validatorSelection.removeOperationalValidator(enodeHigh, enodeLow);
        vm.stopPrank();

        address[] memory active = validatorSelection.getValidators();
        assertEq(active.length, 5);
        for (uint256 i; i < active.length; i++) {
            assertNotEq(active[i], validator);
        }
    }

    function test_addEligibleValidator() public {
        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit EligibleValidatorAdded(validator6.addr, false);
        validatorSelection.addEligibleValidatorByAddress(validator6.addr, false);

        assertEq(validatorSelection.getEligibleValidators().length, 6);
        assertEq(validatorSelection.getValidators().length, 5);
        assertEq(validatorSelection.getProtectedValidators().length, 5);
    }

    function test_addEligibleValidator_WithOperationalActivation() public {
        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit EligibleValidatorAdded(validator6.addr, true);
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorAdded(validator6.addr);
        validatorSelection.addEligibleValidatorByAddress(validator6.addr, true);

        assertEq(validatorSelection.getEligibleValidators().length, 6);
        address[] memory active = validatorSelection.getValidators();
        assertEq(active.length, 6);
        assertEq(active[5], validator6.addr);
        address[] memory added = validatorSelection.getProtectedValidators();
        assertEq(added.length, 6);
        assertEq(added[5], validator6.addr);
    }

    function test_addEligibleValidator_RevertsIfAlreadyEligible() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(AlreadyEligibleNode.selector, validator1.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.addEligibleValidatorByAddress(validator1.addr, false);
    }

    function test_addEligibleValidator_RevertsIfZeroAddress() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidValidatorAddress.selector, address(0));
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.addEligibleValidatorByAddress(address(0), false);
    }

    function test_addEligibleValidator_RevertsIfNotGovernance() public {
        Vm.Wallet memory notGovernance = vm.createWallet(1234);
        vm.prank(notGovernance.addr);
        _expectRevertUnauthorized(notGovernance.addr);
        validatorSelection.addEligibleValidatorByAddress(validator6.addr, false);
    }

    function test_addEligibleValidator_AdjustsBlocksWithoutProposeThreshold() public {
        vm.startPrank(address(governanceMock));
        validatorSelection.setSelectionParameters(initialBlocksBetweenSelection, 5);

        vm.expectEmit(true, true, true, true);
        emit SelectionParametersUpdated(initialBlocksBetweenSelection, 6);
        validatorSelection.addEligibleValidatorByAddress(validator6.addr, false);
        vm.stopPrank();

        assertEq(validatorSelection.blocksWithoutProposeThreshold(), 6);
    }

    function test_addEligibleValidator_ViaEnode() public {
        (bytes32 enodeHigh, bytes32 enodeLow, address validator) = _createEnodeValidator();

        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit EligibleValidatorAdded(validator, false);
        validatorSelection.addEligibleValidator(enodeHigh, enodeLow, false);

        assertEq(validatorSelection.getEligibleValidators().length, 6);
    }

    function test_removeEligibleValidator() public {
        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit EligibleValidatorRemoved(validator1.addr);
        validatorSelection.removeEligibleValidatorByAddress(validator1.addr);

        address[] memory eligible = validatorSelection.getEligibleValidators();
        assertEq(eligible.length, 4);
        for (uint256 i; i < eligible.length; i++) {
            assertNotEq(eligible[i], validator1.addr);
        }
    }

    function test_removeEligibleValidator_DoesNotAdjustBlocksWithoutProposeThreshold() public {
        vm.startPrank(address(governanceMock));
        validatorSelection.setSelectionParameters(initialBlocksBetweenSelection, 5);

        validatorSelection.removeEligibleValidatorByAddress(validator1.addr);
        vm.stopPrank();

        assertEq(validatorSelection.blocksWithoutProposeThreshold(), 5);
    }

    function test_removeEligibleValidator_RemovesFromOperationalAndAdded() public {
        assertEq(validatorSelection.getProtectedValidators().length, 5);

        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorManuallyRemoved(validator1.addr);
        vm.expectEmit(true, true, true, true);
        emit EligibleValidatorRemoved(validator1.addr);
        validatorSelection.removeEligibleValidatorByAddress(validator1.addr);

        assertEq(validatorSelection.getEligibleValidators().length, 4);
        address[] memory active = validatorSelection.getValidators();
        assertEq(active.length, 4);
        for (uint256 i; i < active.length; i++) {
            assertNotEq(active[i], validator1.addr);
        }
        assertEq(validatorSelection.getProtectedValidators().length, 4);
    }

    function test_removeEligibleValidator_RevertsIfLastOperationalValidator() public {
        vm.startPrank(address(governanceMock));
        validatorSelection.removeOperationalValidatorByAddress(validator2.addr);
        validatorSelection.removeOperationalValidatorByAddress(validator3.addr);
        validatorSelection.removeOperationalValidatorByAddress(validator4.addr);
        validatorSelection.removeOperationalValidatorByAddress(validator5.addr);

        bytes memory expectedError = abi.encodeWithSelector(FewOperationalValidators.selector);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.removeEligibleValidatorByAddress(validator1.addr);
        vm.stopPrank();

        assertEq(validatorSelection.getEligibleValidators().length, 5);
        assertEq(validatorSelection.getValidators().length, 1);
    }

    function test_removeEligibleValidator_RevertsIfNotEligible() public {
        Vm.Wallet memory notEligible = vm.createWallet(1234);
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(NotEligibleNode.selector, notEligible.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.removeEligibleValidatorByAddress(notEligible.addr);
    }

    function test_removeEligibleValidator_RevertsIfNotGovernance() public {
        Vm.Wallet memory notGovernance = vm.createWallet(1234);
        vm.prank(notGovernance.addr);
        _expectRevertUnauthorized(notGovernance.addr);
        validatorSelection.removeEligibleValidatorByAddress(validator1.addr);
    }

    function test_removeEligibleValidator_ViaEnode() public {
        (bytes32 enodeHigh, bytes32 enodeLow, address validator) = _createEnodeValidator();

        vm.startPrank(address(governanceMock));
        validatorSelection.addEligibleValidator(enodeHigh, enodeLow, false);
        assertEq(validatorSelection.getEligibleValidators().length, 6);

        vm.expectEmit(true, true, true, true);
        emit EligibleValidatorRemoved(validator);
        validatorSelection.removeEligibleValidator(enodeHigh, enodeLow);
        vm.stopPrank();

        assertEq(validatorSelection.getEligibleValidators().length, 5);
    }
}
