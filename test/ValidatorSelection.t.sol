// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ValidatorSelection.sol";

contract ValidatorSelectionTest is Test {
    ValidatorSelection validatorSelection;

    address sender = address(0x123);

    address validator1 = address(0x1);
    address validator2 = address(0x2);
    address validator3 = address(0x3);

    event MonitorExecuted(address indexed executor);
    event SelectionExecuted(address indexed executor);
    event ValidatorRemoved(address indexed removed);

    function setUp() public {
        validatorSelection = new ValidatorSelection();
        validatorSelection.setBlocksBetweenSelection(1);
        validatorSelection.setBlocksWithoutProposeThreshold(10);
        validatorSelection.addElegibleValidator(validator1);
        validatorSelection.addElegibleValidator(validator2);
        validatorSelection.addElegibleValidator(validator3);
    }

    function test_setBlocksBetweenSelection() public {
        assertEq(validatorSelection.blocksBetweenSelection(), 1);
        validatorSelection.setBlocksBetweenSelection(10);
        assertEq(validatorSelection.blocksBetweenSelection(), 10);
    }

    function test_setBlocksWithoutProposeThreshold() public {
        assertEq(validatorSelection.blocksWithoutProposeThreshold(), 10);
        validatorSelection.setBlocksWithoutProposeThreshold(100);
        assertEq(validatorSelection.blocksWithoutProposeThreshold(), 100);
    }

    function test_getActiveValidators() public {
        address[] memory active = validatorSelection.getActiveValidators();
        assertEq(active.length, 0);
    }

    function test_monitorsValidators() public {
        address proposer = validator1;
        vm.coinbase(proposer);

        vm.prank(sender);
        vm.expectEmit(true, false, false, false);
        emit MonitorExecuted(sender);
        vm.expectEmit(true, false, false, false);
        emit SelectionExecuted(sender);
        validatorSelection.monitorsValidators();
        assertEq(validatorSelection.lastBlockProposedBy(proposer), block.number);
    }

    function test_multipleCallsTomonitorsValidators() public {
        address proposer = validator1;
        vm.coinbase(validator1);

        vm.prank(sender);
        vm.expectEmit(true, false, false, false);
        emit MonitorExecuted(sender);
        vm.expectEmit(true, false, false, false);
        emit SelectionExecuted(sender);
        validatorSelection.monitorsValidators();
        validatorSelection.addOperationalValidator(proposer);
        
        vm.expectRevert("Monitoring already executed in this block.");
        validatorSelection.monitorsValidators();
    }

    function test_selectValidatorsWithoutRemotion() public {
        address proposer = validator1;
        vm.coinbase(proposer);

        vm.prank(sender);
        vm.expectEmit(true, false, false, false);
        emit SelectionExecuted(sender);
        validatorSelection.monitorsValidators();
        validatorSelection.addOperationalValidator(proposer);    
        assertEq(validatorSelection.lastBlockProposedBy(proposer), block.number);
    }

    function test_selectValidatorsWithRemotion() public {
        address proposer = validator1;
        vm.coinbase(proposer);

        vm.prank(sender);
        vm.expectEmit(true, false, false, false);
        emit SelectionExecuted(sender);
        validatorSelection.monitorsValidators();
        validatorSelection.addOperationalValidator(proposer); 
        assertEq(validatorSelection.lastBlockProposedBy(proposer), block.number);

        vm.roll(block.number + validatorSelection.blocksWithoutProposeThreshold() + 1);

        proposer = validator2;
        vm.coinbase(proposer);

        vm.prank(sender);
        vm.expectEmit(true, false, false, false);
        emit ValidatorRemoved(validator1);
        vm.expectEmit(true, false, false, false);
        emit SelectionExecuted(sender);
        validatorSelection.monitorsValidators();
        validatorSelection.addOperationalValidator(proposer);
    }
}
