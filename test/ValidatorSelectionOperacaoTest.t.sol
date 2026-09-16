// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Vm} from "lib/forge-std/src/Test.sol";
import {OperationMode} from "src/interfaces/IValidatorSelection.sol";
import {ValidatorSelectionBaseTest} from "test/ValidatorSelectionBaseTest.t.sol";

contract ValidatorSelectionOperacaoTest is ValidatorSelectionBaseTest {
    Vm.Wallet validator6 = vm.createWallet(6);
    Vm.Wallet validator7 = vm.createWallet(7);
    Vm.Wallet validator8 = vm.createWallet(8);

    function _activateAsOperational(address validator) internal {
        vm.prank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator, true);
    }

    function test_setOperationMode() public {
        assertEq(uint256(validatorSelection.operationMode()), uint256(OperationMode.Manual));

        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit OperationModeChanged(OperationMode.Automatic);
        validatorSelection.setOperationMode(OperationMode.Automatic);

        assertEq(uint256(validatorSelection.operationMode()), uint256(OperationMode.Automatic));
        assertEq(validatorSelection.cycleStartBlock(), block.number);
        assertEq(validatorSelection.nextSelectionBlock(), block.number + initialBlocksBetweenSelection);
        assertEq(validatorSelection.getProtectedValidators().length, 5);
    }

    function test_setOperationMode_ProtectsOperationalValidatorsInFirstCycle() public {
        vm.roll(50);
        _enableAutomaticMode();

        vm.coinbase(sender);
        vm.roll(50 + initialBlocksWithoutProposeThreshold + 1);
        vm.prank(sender);
        validatorSelection.executeMonitoring();

        assertEq(validatorSelection.getValidators().length, 5);
        assertEq(validatorSelection.getProtectedValidators().length, 0);
    }

    function test_setOperationMode_BackToManual() public {
        _enableAutomaticMode();
        uint256 nextSelectionBlock = validatorSelection.nextSelectionBlock();

        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit OperationModeChanged(OperationMode.Manual);
        validatorSelection.setOperationMode(OperationMode.Manual);

        assertEq(uint256(validatorSelection.operationMode()), uint256(OperationMode.Manual));
        assertEq(validatorSelection.nextSelectionBlock(), nextSelectionBlock);
    }

    function test_setOperationMode_RevertsIfNotGovernance() public {
        Vm.Wallet memory notGovernance = vm.createWallet(1234);
        vm.prank(notGovernance.addr);
        _expectRevertUnauthorized(notGovernance.addr);
        validatorSelection.setOperationMode(OperationMode.Automatic);
    }

    function test_setOperationMode_RevertsIfInvalidMode() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidOperationMode.selector);
        vm.expectRevert(expectedError, address(validatorSelection));
        (bool success,) = address(validatorSelection).call(abi.encodeWithSignature("setOperationMode(uint8)", uint8(2)));
        assertFalse(success);
    }

    function test_setSelectionParameters() public {
        assertEq(validatorSelection.blocksBetweenSelection(), initialBlocksBetweenSelection);
        assertEq(validatorSelection.blocksWithoutProposeThreshold(), initialBlocksWithoutProposeThreshold);

        uint256 updateBlocksBetweenSelection = 10;
        uint256 updateBlocksWithoutProposeThreshold = 100;
        vm.roll(50);

        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit SelectionParametersUpdated(updateBlocksBetweenSelection, updateBlocksWithoutProposeThreshold);
        validatorSelection.setSelectionParameters(updateBlocksBetweenSelection, updateBlocksWithoutProposeThreshold);

        assertEq(validatorSelection.blocksBetweenSelection(), updateBlocksBetweenSelection);
        assertEq(validatorSelection.blocksWithoutProposeThreshold(), updateBlocksWithoutProposeThreshold);
        assertEq(validatorSelection.cycleStartBlock(), 50);
        assertEq(validatorSelection.nextSelectionBlock(), 50 + updateBlocksBetweenSelection);
    }

    function test_setSelectionParameters_ProtectsOperationalValidators() public {
        _enableAutomaticMode();
        _closeCurrentCycle(10);

        vm.prank(address(governanceMock));
        validatorSelection.setSelectionParameters(initialBlocksBetweenSelection, initialBlocksWithoutProposeThreshold);

        assertEq(validatorSelection.getProtectedValidators().length, 5);
    }

    function test_setSelectionParameters_RevertsIfBlocksBetweenSelectionLessThanOne() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidBlocksBetweenSelection.selector);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.setSelectionParameters(0, initialBlocksWithoutProposeThreshold);
    }

    function test_setSelectionParameters_RevertsIfThresholdLessThanEligibleValidators() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidBlocksWithoutProposeThreshold.selector);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.setSelectionParameters(initialBlocksBetweenSelection, 4);
    }

    function test_setSelectionParameters_RevertsIfNotGovernance() public {
        Vm.Wallet memory notGovernance = vm.createWallet(1234);
        vm.prank(notGovernance.addr);
        _expectRevertUnauthorized(notGovernance.addr);
        validatorSelection.setSelectionParameters(10, 100);
    }

    function test_executeMonitoring_DoesNothingInManualMode() public {
        Vm.Wallet memory proposer = validator1;
        vm.roll(initialNextSelectionBlock);
        vm.coinbase(proposer.addr);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit MonitorExecuted(sender, block.number);
        validatorSelection.executeMonitoring();

        assertEq(validatorSelection.lastBlockProposedBy(proposer.addr), 0);
        assertEq(validatorSelection.nextSelectionBlock(), initialNextSelectionBlock);
    }

    function test_executeMonitoring() public {
        _enableAutomaticMode();
        Vm.Wallet memory proposer = validator1;
        vm.roll(validatorSelection.nextSelectionBlock());
        vm.coinbase(proposer.addr);
        assertEq(validatorSelection.lastBlockProposedBy(proposer.addr), 0);

        uint256 blockNumber = block.number;
        assertEq(validatorSelection.nextSelectionBlock(), blockNumber);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit MonitorExecuted(sender, block.number);
        vm.expectEmit(true, true, true, true);
        emit SelectionExecuted(_initialOperationalAddresses());
        validatorSelection.executeMonitoring();
        assertEq(validatorSelection.lastBlockProposedBy(proposer.addr), blockNumber);

        uint256 expectedNextSelectionBlock = blockNumber + validatorSelection.blocksBetweenSelection();
        assertEq(validatorSelection.nextSelectionBlock(), expectedNextSelectionBlock);
        assertEq(validatorSelection.cycleStartBlock(), blockNumber);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit MonitorExecuted(sender, block.number);
        validatorSelection.executeMonitoring();
        assertEq(validatorSelection.nextSelectionBlock(), expectedNextSelectionBlock);
    }

    function test_executeMonitoring_AntiDuplicateInSameBlock() public {
        _enableAutomaticMode();
        vm.roll(validatorSelection.nextSelectionBlock());

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit MonitorExecuted(sender, block.number);
        vm.expectEmit(true, true, true, true);
        emit SelectionExecuted(_initialOperationalAddresses());
        validatorSelection.executeMonitoring();
        assertEq(validatorSelection.lastMonitoredBlock(), block.number);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit MonitorExecuted(sender, block.number);
        validatorSelection.executeMonitoring();
    }

    function test_executeMonitoring_RecordsProposerBeforeSelectionBlock() public {
        _enableAutomaticMode();
        Vm.Wallet memory proposer = validator1;
        vm.coinbase(proposer.addr);
        assertEq(validatorSelection.lastBlockProposedBy(proposer.addr), 0);

        uint256 blockNumber = block.number;
        uint256 nextSelectionBlock = validatorSelection.nextSelectionBlock();
        assertLt(blockNumber, nextSelectionBlock);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit MonitorExecuted(sender, block.number);
        validatorSelection.executeMonitoring();
        assertEq(validatorSelection.lastBlockProposedBy(proposer.addr), blockNumber);
        assertEq(validatorSelection.nextSelectionBlock(), nextSelectionBlock);
    }

    function test_executeMonitoring_SelectsAfterTargetBlock() public {
        _enableAutomaticMode();
        Vm.Wallet memory proposer = validator1;
        vm.coinbase(proposer.addr);

        uint256 nextSelectionBlock = validatorSelection.nextSelectionBlock();
        uint256 blockNumber = nextSelectionBlock + 5;
        vm.roll(blockNumber);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit MonitorExecuted(sender, block.number);
        vm.expectEmit(true, true, true, true);
        emit SelectionExecuted(_initialOperationalAddresses());
        validatorSelection.executeMonitoring();

        assertEq(validatorSelection.nextSelectionBlock(), blockNumber + initialBlocksBetweenSelection);
        assertEq(validatorSelection.cycleStartBlock(), blockNumber);
    }

    function test_executeMonitoring_RemovesInactiveValidator() public {
        assertEq(validatorSelection.getValidators().length, 5);

        _enableAutomaticMode();
        assertEq(validatorSelection.getProtectedValidators().length, 5);

        assertEq(block.number, 1);
        _closeCurrentCycle(10);

        uint256 nextSelectionBlock = 100;

        _setLastBlockProposedBy(validator2.addr, nextSelectionBlock - 2);
        _setLastBlockProposedBy(validator3.addr, nextSelectionBlock - 3);
        _setLastBlockProposedBy(validator4.addr, nextSelectionBlock - 4);
        _setLastBlockProposedBy(validator5.addr, nextSelectionBlock - 5);

        assertEq(validatorSelection.lastBlockProposedBy(validator1.addr), 0);

        address[] memory expectedAfterSelection = new address[](4);
        expectedAfterSelection[0] = validator2.addr;
        expectedAfterSelection[1] = validator3.addr;
        expectedAfterSelection[2] = validator4.addr;
        expectedAfterSelection[3] = validator5.addr;

        vm.roll(nextSelectionBlock);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit MonitorExecuted(sender, block.number);
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorRemoved(validator1.addr);
        vm.expectEmit(false, false, false, false);
        emit SelectionExecuted(expectedAfterSelection);
        validatorSelection.executeMonitoring();

        assertEq(validatorSelection.getValidators().length, 4);
        address[] memory activeValidators = validatorSelection.getValidators();
        for (uint256 i; i < activeValidators.length; i++) {
            assertNotEq(activeValidators[i], validator1.addr);
        }
        assertEq(validatorSelection.getEligibleValidators().length, 5);
        assertEq(validatorSelection.nextSelectionBlock(), nextSelectionBlock + initialBlocksBetweenSelection);
    }

    function test_executeMonitoring_KeepsRecentlyAddedValidators() public {
        _enableAutomaticMode();
        assertEq(validatorSelection.getProtectedValidators().length, 5);

        uint256 nextSelectionBlock = 100;
        vm.coinbase(sender);
        vm.roll(nextSelectionBlock);

        vm.prank(sender);
        validatorSelection.executeMonitoring();

        assertEq(validatorSelection.getValidators().length, 5);
        assertEq(validatorSelection.getProtectedValidators().length, 0);
    }

    function test_executeMonitoring_KeepsAllInactiveValidatorsIfMinimumWouldBeViolated() public {
        _enableAutomaticMode();
        _closeCurrentCycle(10);

        uint256 nextSelectionBlock = 100;

        _setLastBlockProposedBy(validator3.addr, nextSelectionBlock - 2);
        _setLastBlockProposedBy(validator4.addr, nextSelectionBlock - 3);
        _setLastBlockProposedBy(validator5.addr, nextSelectionBlock - 4);

        vm.coinbase(sender);
        vm.roll(nextSelectionBlock);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit SelectionExecuted(_initialOperationalAddresses());
        validatorSelection.executeMonitoring();

        assertEq(validatorSelection.getValidators().length, 5);
        assertTrue(validatorSelection.isOperational(validator1.addr));
        assertTrue(validatorSelection.isOperational(validator2.addr));
    }

    function test_executeMonitoring_RemovesAllInactiveValidatorsAtOnce() public {
        _activateAsOperational(validator6.addr);
        _activateAsOperational(validator7.addr);
        _activateAsOperational(validator8.addr);
        assertEq(validatorSelection.getValidators().length, 8);

        _enableAutomaticMode();
        _closeCurrentCycle(10);

        uint256 nextSelectionBlock = 100;

        _setLastBlockProposedBy(validator5.addr, nextSelectionBlock - 2);
        _setLastBlockProposedBy(validator6.addr, nextSelectionBlock - 3);
        _setLastBlockProposedBy(validator7.addr, nextSelectionBlock - 4);
        _setLastBlockProposedBy(validator8.addr, nextSelectionBlock - 5);

        vm.coinbase(sender);
        vm.roll(nextSelectionBlock);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorRemoved(validator1.addr);
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorRemoved(validator2.addr);
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorRemoved(validator3.addr);
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorRemoved(validator4.addr);
        validatorSelection.executeMonitoring();

        assertEq(validatorSelection.getValidators().length, 4);
        assertFalse(validatorSelection.isOperational(validator1.addr));
        assertFalse(validatorSelection.isOperational(validator2.addr));
        assertFalse(validatorSelection.isOperational(validator3.addr));
        assertFalse(validatorSelection.isOperational(validator4.addr));
        assertEq(validatorSelection.getEligibleValidators().length, 8);
    }

    function test_executeMonitoring_KeepsThreeInactiveValidatorsIfMinimumWouldBeViolated() public {
        _activateAsOperational(validator6.addr);
        assertEq(validatorSelection.getValidators().length, 6);

        _enableAutomaticMode();
        _closeCurrentCycle(10);

        uint256 nextSelectionBlock = 100;

        _setLastBlockProposedBy(validator4.addr, nextSelectionBlock - 2);
        _setLastBlockProposedBy(validator5.addr, nextSelectionBlock - 3);
        _setLastBlockProposedBy(validator6.addr, nextSelectionBlock - 4);

        vm.coinbase(sender);
        vm.roll(nextSelectionBlock);

        vm.prank(sender);
        validatorSelection.executeMonitoring();

        assertEq(validatorSelection.getValidators().length, 6);
        assertTrue(validatorSelection.isOperational(validator1.addr));
        assertTrue(validatorSelection.isOperational(validator2.addr));
        assertTrue(validatorSelection.isOperational(validator3.addr));
    }

    function test_executeMonitoring_KeepsAllValidatorsIfEveryoneIsInactive() public {
        _enableAutomaticMode();
        _closeCurrentCycle(10);

        vm.coinbase(sender);
        vm.roll(100);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit SelectionExecuted(_initialOperationalAddresses());
        validatorSelection.executeMonitoring();

        assertEq(validatorSelection.getValidators().length, 5);
    }

    function test_executeMonitoring_ProtectedInactiveValidatorVetoesTheBatch() public {
        _enableAutomaticMode();
        _closeCurrentCycle(10);
        assertEq(validatorSelection.getProtectedValidators().length, 0);

        _activateAsOperational(validator6.addr);
        assertTrue(validatorSelection.isProtected(validator6.addr));

        uint256 nextSelectionBlock = 100;

        _setLastBlockProposedBy(validator3.addr, nextSelectionBlock - 2);
        _setLastBlockProposedBy(validator4.addr, nextSelectionBlock - 3);
        _setLastBlockProposedBy(validator5.addr, nextSelectionBlock - 4);

        vm.coinbase(sender);
        vm.roll(nextSelectionBlock);

        vm.prank(sender);
        validatorSelection.executeMonitoring();

        assertEq(validatorSelection.getValidators().length, 6);
        assertTrue(validatorSelection.isOperational(validator1.addr));
        assertTrue(validatorSelection.isOperational(validator2.addr));
        assertTrue(validatorSelection.isOperational(validator6.addr));
        assertFalse(validatorSelection.isProtected(validator6.addr));
    }

    function test_executeMonitoring_MeasuresInactivityFromCycleStart() public {
        _enableAutomaticMode();
        _closeCurrentCycle(10);
        assertEq(validatorSelection.cycleStartBlock(), 10);
        assertEq(validatorSelection.lastBlockProposedBy(validator5.addr), 0);

        uint256 firstSelectionBlock = 20;
        _setLastBlockProposedBy(validator1.addr, firstSelectionBlock - 1);
        _setLastBlockProposedBy(validator2.addr, firstSelectionBlock - 1);
        _setLastBlockProposedBy(validator3.addr, firstSelectionBlock - 1);
        _setLastBlockProposedBy(validator4.addr, firstSelectionBlock - 1);

        vm.coinbase(sender);
        vm.roll(firstSelectionBlock);
        vm.prank(sender);
        validatorSelection.executeMonitoring();

        assertEq(validatorSelection.getValidators().length, 5);
        assertTrue(validatorSelection.isOperational(validator5.addr));
        assertEq(validatorSelection.cycleStartBlock(), firstSelectionBlock);

        uint256 secondSelectionBlock = 31;
        _setLastBlockProposedBy(validator1.addr, secondSelectionBlock - 1);
        _setLastBlockProposedBy(validator2.addr, secondSelectionBlock - 1);
        _setLastBlockProposedBy(validator3.addr, secondSelectionBlock - 1);
        _setLastBlockProposedBy(validator4.addr, secondSelectionBlock - 1);

        vm.coinbase(sender);
        vm.roll(secondSelectionBlock);
        vm.prank(sender);
        validatorSelection.executeMonitoring();

        assertEq(validatorSelection.getValidators().length, 4);
        assertFalse(validatorSelection.isOperational(validator5.addr));
    }

    function test_executeMonitoring_ProductionInfoInitializedAtCycleStart() public {
        vm.roll(15);
        _enableAutomaticMode();
        assertEq(validatorSelection.cycleStartBlock(), 15);

        vm.coinbase(sender);
        vm.roll(20);

        vm.prank(sender);
        validatorSelection.executeMonitoring();

        assertEq(validatorSelection.getValidators().length, 5);
    }
}
