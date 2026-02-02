// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, Vm, console, stdStorage, StdStorage} from "lib/forge-std/src/Test.sol";
import {Upgrades} from "lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";
import {ValidatorSelection} from "src/ValidatorSelection.sol";
import {AdminMock} from "test/mocks/AdminMock.sol";
import {GovernanceMock} from "test/mocks/GovernanceMock.sol";
import {NodeRulesV2Mock} from "test/mocks/NodeRulesV2Mock.sol";
import {AccountRulesV2Mock} from "test/mocks/AccountRulesV2Mock.sol";

contract ValidatorSelectionTest is Test {
    using stdStorage for StdStorage;

    ValidatorSelection validatorSelection;
    GovernanceMock governanceMock;
    AdminMock adminMock;
    NodeRulesV2Mock nodeRulesMock;
    AccountRulesV2Mock accountRulesMock;

    address proxyContractAddress;
    address sender = address(0x123);

    Vm.Wallet validator1 = vm.createWallet(1);
    Vm.Wallet validator2 = vm.createWallet(2);
    Vm.Wallet validator3 = vm.createWallet(3);
    Vm.Wallet validator4 = vm.createWallet(4);
    Vm.Wallet validator5 = vm.createWallet(5);

    uint256 public initialNextSelectionBlock = 10;
    uint256 public initialBlocksBetweenSelection = 2;
    uint256 public initialBlocksWithoutProposeThreshold = 10;
    uint256 public constant MIN_BLOCKS_BETWEEN_SELECTION = 10;

    event SelectionExecuted(uint256 indexed blockNumber, uint256 cursor, uint256 processed, uint256 found);
    event ValidatorsRemoved(address[] removed);
    event EligibleValidatorAdded(address indexed validator);
    event OperationalValidatorAdded(address indexed validator, uint256 blockNumber);
    event OperationalValidatorRemoved(address indexed validator, address indexed removedBy);

    error UnauthorizedAccess(address account);

    function setUp() public {
        adminMock = new AdminMock();
        accountRulesMock = new AccountRulesV2Mock();
        nodeRulesMock = new NodeRulesV2Mock();

        address[] memory initialElegibleValidators = new address[](5);
        initialElegibleValidators[0] = validator1.addr;
        initialElegibleValidators[1] = validator2.addr;
        initialElegibleValidators[2] = validator3.addr;
        initialElegibleValidators[3] = validator4.addr;
        initialElegibleValidators[4] = validator5.addr;

        proxyContractAddress = Upgrades.deployUUPSProxy(
            "ValidatorSelection.sol",
            abi.encodeCall(
                ValidatorSelection.initialize,
                (
                    adminMock,
                    accountRulesMock,
                    nodeRulesMock,
                    initialElegibleValidators,
                    initialBlocksBetweenSelection,
                    initialBlocksWithoutProposeThreshold,
                    initialNextSelectionBlock
                )
            )
        );
        validatorSelection = ValidatorSelection(proxyContractAddress);

        bytes32 implSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        address validatorSelectionImplementationAddress =
            address(uint160(uint256(vm.load(proxyContractAddress, implSlot))));

        governanceMock = new GovernanceMock(address(proxyContractAddress));
        vm.prank(address(governanceMock));
        adminMock.addAdmin(address(governanceMock));

        console.log("UUProxyS:", address(proxyContractAddress));
        console.log("ValidatorSelection:", address(validatorSelectionImplementationAddress));
        console.log("GovernanceMock:", address(governanceMock));
        console.log("AdminMock:", address(adminMock));
    }

    function test_monitorsValidators() public {
        Vm.Wallet memory proposer = validator1;
        vm.roll(validatorSelection.nextSelectionBlock());
        vm.coinbase(proposer.addr);
        
        uint256 blockNumber = block.number;
        
        vm.prank(sender);
        validatorSelection.monitorsValidators();
        
        assertEq(validatorSelection.lastBlockProposedBy(proposer.addr), blockNumber);
        uint256 blocksBetweenSelection = validatorSelection.blocksBetweenSelection();
        assertEq(validatorSelection.nextSelectionBlock(), blockNumber + blocksBetweenSelection);
    }

    function test_monitorsValidatorsWithSelection() public {
        vm.startPrank(address(governanceMock));
        validatorSelection.addOperationalValidator(validator1.addr);
        validatorSelection.addOperationalValidator(validator2.addr);
        validatorSelection.addOperationalValidator(validator3.addr);
        validatorSelection.addOperationalValidator(validator4.addr);
        validatorSelection.addOperationalValidator(validator5.addr);
        vm.stopPrank();
        
        assertEq(validatorSelection.getActiveValidators().length, 5);

        uint256 nextSelectionBlock = 100;
        vm.prank(address(governanceMock));
        validatorSelection.setNextSelectionBlock(nextSelectionBlock);

        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator2.addr).checked_write(nextSelectionBlock - 2);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator3.addr).checked_write(nextSelectionBlock - 3);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator4.addr).checked_write(nextSelectionBlock - 4);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator5.addr).checked_write(nextSelectionBlock - 5);

        assertEq(validatorSelection.lastBlockProposedBy(validator1.addr), 1);

        vm.roll(nextSelectionBlock);
        vm.prank(sender);
        
        address[] memory expectedRemovedValidators = new address[](1);
        expectedRemovedValidators[0] = validator1.addr;
        
        vm.expectEmit(true, true, true, true);
        emit ValidatorsRemoved(expectedRemovedValidators);
        validatorSelection.monitorsValidators();

        assertEq(validatorSelection.getActiveValidators().length, 4);
        address[] memory activeValidators = validatorSelection.getActiveValidators();
        for (uint256 i; i < activeValidators.length; i++) {
            assertNotEq(activeValidators[i], validator1.addr);
        }

        uint256 expectedNextSelectionBlock = nextSelectionBlock + initialBlocksBetweenSelection;
        assertEq(validatorSelection.nextSelectionBlock(), expectedNextSelectionBlock);
    }

    function test_BatchProcessing_LargeSet() public {
        uint256 batchSize = 50;
        vm.prank(address(governanceMock));
        validatorSelection.setBatchSize(batchSize);
        
        vm.startPrank(address(governanceMock));
        for (uint256 i = 1; i <= 10; i++) {
            address newValidator = address(uint160(0x1000 + i));
            validatorSelection.addEligibleValidator(newValidator);
            validatorSelection.addOperationalValidator(newValidator);
        }
        vm.stopPrank();
        
        assertEq(validatorSelection.getActiveValidators().length, 10);
        
        uint256 currentBlock = block.number;
        uint256 nextSelectionBlock = currentBlock + MIN_BLOCKS_BETWEEN_SELECTION + 100;
        vm.prank(address(governanceMock));
        validatorSelection.setNextSelectionBlock(nextSelectionBlock);
        vm.roll(nextSelectionBlock);
        
        vm.prank(sender);
        validatorSelection.monitorsValidators();
        
        assertLe(validatorSelection.getActiveValidators().length, 10);
    }

    function test_addOperationalValidator() public {
        vm.prank(address(governanceMock));
        validatorSelection.addOperationalValidator(validator1.addr);
        
        assertTrue(validatorSelection.isOperationalValidator(validator1.addr));
        assertEq(validatorSelection.lastBlockProposedBy(validator1.addr), block.number);
    }

    function test_removeOperationalValidator() public {
        vm.prank(address(governanceMock));
        validatorSelection.addOperationalValidator(validator1.addr);
        assertTrue(validatorSelection.isOperationalValidator(validator1.addr));
        
        vm.prank(address(governanceMock));
        validatorSelection.removeOperationalValidator(validator1.addr);
        
        assertFalse(validatorSelection.isOperationalValidator(validator1.addr));
        assertEq(validatorSelection.lastBlockProposedBy(validator1.addr), 0);
    }

    function test_addEligibleValidator() public {
        address newValidator = address(0x999);
        
        vm.prank(address(governanceMock));
        validatorSelection.addEligibleValidator(newValidator);
        
        assertTrue(validatorSelection.isEligibleValidator(newValidator));
        assertEq(validatorSelection.getEligibleValidatorsCount(), 6);
    }

    function test_removeEligibleValidator() public {
        assertEq(validatorSelection.getEligibleValidatorsCount(), 5);
        
        vm.prank(address(governanceMock));
        validatorSelection.removeEligibleValidator(validator1.addr);
        
        assertFalse(validatorSelection.isEligibleValidator(validator1.addr));
        assertEq(validatorSelection.getEligibleValidatorsCount(), 4);
    }

    function test_setBlocksBetweenSelection() public {
        uint256 newValue = 100;
        vm.prank(address(governanceMock));
        validatorSelection.setBlocksBetweenSelection(newValue);
        assertEq(validatorSelection.blocksBetweenSelection(), newValue);
    }

    function test_setBlocksWithoutProposeThreshold() public {
        uint256 newValue = 100;
        vm.prank(address(governanceMock));
        validatorSelection.setBlocksWithoutProposeThreshold(newValue);
        assertEq(validatorSelection.blocksWithoutProposeThreshold(), newValue);
    }

    function test_setBatchSize() public {
        uint256 newValue = 100;
        vm.prank(address(governanceMock));
        validatorSelection.setBatchSize(newValue);
        assertEq(validatorSelection.batchSize(), newValue);
    }

    function test_setNextSelectionBlock() public {
        uint256 newValue = 200;
        vm.prank(address(governanceMock));
        validatorSelection.setNextSelectionBlock(newValue);
        assertEq(validatorSelection.nextSelectionBlock(), newValue);
    }

    function test_addOperationalValidator_RevertsIfNotEligible() public {
        address notEligible = address(0x999);
        
        vm.prank(address(governanceMock));
        vm.expectRevert(abi.encodeWithSignature("NotEligibleNode(address)", notEligible));
        validatorSelection.addOperationalValidator(notEligible);
    }

    function test_addOperationalValidator_RevertsIfNotGovernance() public {
        vm.expectRevert(abi.encodeWithSelector(UnauthorizedAccess.selector, sender));
        vm.prank(sender);
        validatorSelection.addOperationalValidator(validator1.addr);
    }

    function test_setBatchSize_RevertsWithInvalidValue() public {
        vm.prank(address(governanceMock));
        vm.expectRevert();
        validatorSelection.setBatchSize(5);
        
        vm.prank(address(governanceMock));
        vm.expectRevert();
        validatorSelection.setBatchSize(1000);
    }

    function test_setBlocksBetweenSelection_RevertsWithInvalidValue() public {
        vm.prank(address(governanceMock));
        vm.expectRevert();
        validatorSelection.setBlocksBetweenSelection(5);
    }

    function test_CannotModifyValidatorsDuringSelection() public {
        vm.startPrank(address(governanceMock));
        
        validatorSelection.setBatchSize(10);
        
        for (uint256 i = 1; i <= 15; i++) {
            address validator = address(uint160(0x2000 + i));
            validatorSelection.addEligibleValidator(validator);
            validatorSelection.addOperationalValidator(validator);
        }
        
        vm.stopPrank();
        
        for (uint256 i = 1; i <= 15; i++) {
            address validator = address(uint160(0x2000 + i));
            stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
                .with_key(validator).checked_write(95);
        }
        
        uint256 nextSelectionBlock = 100;
        vm.prank(address(governanceMock));
        validatorSelection.setNextSelectionBlock(nextSelectionBlock);
        
        vm.roll(nextSelectionBlock);
        vm.prank(sender);
        validatorSelection.monitorsValidators();
        
        assertTrue(validatorSelection.selectionInProgress(), "Selecao deveria estar em progresso");
        
        address newValidator = address(0x999);
        vm.prank(address(governanceMock));
        validatorSelection.addEligibleValidator(newValidator);
        
        vm.prank(address(governanceMock));
        vm.expectRevert(abi.encodeWithSignature("CannotModifyDuringSelection()"));
        validatorSelection.addOperationalValidator(newValidator);
        
        vm.prank(address(governanceMock));
        vm.expectRevert(abi.encodeWithSignature("CannotModifyDuringSelection()"));
        validatorSelection.removeOperationalValidator(address(uint160(0x2001)));
    }

    function test_ResetStuckSelection() public {
        vm.startPrank(address(governanceMock));
        validatorSelection.setBatchSize(10);
        
        for (uint256 i = 1; i <= 15; i++) {
            address validator = address(uint160(0x3000 + i));
            validatorSelection.addEligibleValidator(validator);
            validatorSelection.addOperationalValidator(validator);
        }
        
        uint256 nextSelectionBlock = 100;
        validatorSelection.setNextSelectionBlock(nextSelectionBlock);
        vm.stopPrank();
        
        for (uint256 i = 1; i <= 15; i++) {
            address validator = address(uint160(0x3000 + i));
            stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
                .with_key(validator).checked_write(95);
        }
        
        vm.roll(nextSelectionBlock);
        vm.prank(sender);
        validatorSelection.monitorsValidators();
        
        assertTrue(validatorSelection.selectionInProgress(), "Selecao deve estar em progresso");
        
        vm.roll(nextSelectionBlock + 500);
        vm.prank(address(governanceMock));
        vm.expectRevert(abi.encodeWithSignature("SelectionNotTimedOut()"));
        validatorSelection.resetStuckSelection();
        
        vm.roll(nextSelectionBlock + 1001);
        
        vm.prank(address(governanceMock));
        validatorSelection.resetStuckSelection();
        
        assertFalse(validatorSelection.selectionInProgress());
        assertEq(validatorSelection.selectionCursor(), 0);
    }

    function test_DynamicLengthProtectsAgainstValidatorChanges() public {
        vm.startPrank(address(governanceMock));
        for (uint256 i = 1; i <= 5; i++) {
            address validator = address(uint160(0x1000 + i));
            validatorSelection.addEligibleValidator(validator);
            validatorSelection.addOperationalValidator(validator);
        }
        
        uint256 nextSelectionBlock = 100;
        validatorSelection.setNextSelectionBlock(nextSelectionBlock);
        validatorSelection.setBatchSize(20);
        vm.stopPrank();
        
        uint256 totalBefore = validatorSelection.getOperationalValidatorsCount();
        assertEq(totalBefore, 5);
        
        vm.roll(nextSelectionBlock);
        vm.prank(sender);
        validatorSelection.monitorsValidators();
        
        assertFalse(validatorSelection.selectionInProgress(), "Selecao deveria ter completado");
    }

    function test_MultipleCallsToMonitorsValidatorsAreSafe() public {
        vm.startPrank(address(governanceMock));
        validatorSelection.addOperationalValidator(validator1.addr);
        validatorSelection.addOperationalValidator(validator2.addr);
        validatorSelection.addOperationalValidator(validator3.addr);
        validatorSelection.addOperationalValidator(validator4.addr);
        vm.stopPrank();
        
        uint256 nextSelectionBlock = 100;
        vm.prank(address(governanceMock));
        validatorSelection.setNextSelectionBlock(nextSelectionBlock);
        
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator1.addr).checked_write(95);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator2.addr).checked_write(95);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator3.addr).checked_write(95);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator4.addr).checked_write(95);
        
        vm.roll(nextSelectionBlock);
        
        vm.prank(sender);
        validatorSelection.monitorsValidators();
        
        uint256 totalAfter1 = validatorSelection.getOperationalValidatorsCount();
        
        vm.prank(sender);
        validatorSelection.monitorsValidators();
        
        uint256 totalAfter2 = validatorSelection.getOperationalValidatorsCount();
        
        assertEq(totalAfter1, totalAfter2, "Multiplas chamadas nao devem alterar estado");
    }

    function test_ValidatorInitializationTimestampIsSafe() public {
        uint256 currentBlock = 500;
        vm.roll(currentBlock);
        
        address newValidator = address(0x888);
        vm.startPrank(address(governanceMock));
        validatorSelection.addEligibleValidator(newValidator);
        validatorSelection.addOperationalValidator(newValidator);
        vm.stopPrank();
        
        assertEq(validatorSelection.lastBlockProposedBy(newValidator), currentBlock);
        
        vm.roll(currentBlock + 50);
        
        assertTrue(validatorSelection.isOperationalValidator(newValidator));
    }

    function test_MinimumValidatorsIsRespected() public {
        vm.startPrank(address(governanceMock));
        validatorSelection.addOperationalValidator(validator1.addr);
        validatorSelection.addOperationalValidator(validator2.addr);
        validatorSelection.addOperationalValidator(validator3.addr);
        validatorSelection.addOperationalValidator(validator4.addr);
        
        uint256 nextSelectionBlock = 100;
        validatorSelection.setNextSelectionBlock(nextSelectionBlock);
        vm.stopPrank();
        
        vm.roll(nextSelectionBlock);
        vm.prank(sender);
        validatorSelection.monitorsValidators();
        
        assertGe(validatorSelection.getOperationalValidatorsCount(), 4);
    }

    function test_SelectionCompletesInSingleTransaction() public {
        vm.startPrank(address(governanceMock));
        validatorSelection.setBatchSize(100);
        validatorSelection.addOperationalValidator(validator1.addr);
        validatorSelection.addOperationalValidator(validator2.addr);
        
        uint256 nextSelectionBlock = 100;
        validatorSelection.setNextSelectionBlock(nextSelectionBlock);
        vm.stopPrank();
        
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator1.addr).checked_write(95);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator2.addr).checked_write(95);
        
        vm.roll(nextSelectionBlock);
        
        vm.prank(sender);
        validatorSelection.monitorsValidators();
        
        assertFalse(validatorSelection.selectionInProgress(), "Selecao deveria ter completado");
        assertEq(validatorSelection.selectionCursor(), 0);
        
        assertGt(validatorSelection.nextSelectionBlock(), nextSelectionBlock);
    }

    function test_ValidatorCanBeReAddedAfterRemoval() public {
        vm.startPrank(address(governanceMock));
        
        validatorSelection.addOperationalValidator(validator1.addr);
        assertTrue(validatorSelection.isOperationalValidator(validator1.addr));
        
        validatorSelection.removeOperationalValidator(validator1.addr);
        assertFalse(validatorSelection.isOperationalValidator(validator1.addr));
        
        validatorSelection.addOperationalValidator(validator1.addr);
        assertTrue(validatorSelection.isOperationalValidator(validator1.addr));
        
        vm.stopPrank();
    }

    function test_CannotAddDuplicateValidator() public {
        vm.startPrank(address(governanceMock));
        
        validatorSelection.addOperationalValidator(validator1.addr);
        
        vm.expectRevert(abi.encodeWithSignature("DuplicateValidator(address)", validator1.addr));
        validatorSelection.addOperationalValidator(validator1.addr);
        
        vm.stopPrank();
    }

    function test_CannotRemoveNonOperationalValidator() public {
        vm.prank(address(governanceMock));
        vm.expectRevert(abi.encodeWithSignature("NotOperationalNode(address)", validator1.addr));
        validatorSelection.removeOperationalValidator(validator1.addr);
    }

    function test_PartialRemovalDuringSelection() public {
        vm.startPrank(address(governanceMock));
        
        validatorSelection.addOperationalValidator(validator1.addr);
        validatorSelection.addOperationalValidator(validator2.addr);
        validatorSelection.addOperationalValidator(validator3.addr);
        validatorSelection.addOperationalValidator(validator4.addr);
        validatorSelection.addOperationalValidator(validator5.addr);
        
        address validator6 = address(0x666);
        validatorSelection.addEligibleValidator(validator6);
        validatorSelection.addOperationalValidator(validator6);
        
        uint256 nextSelectionBlock = 100;
        validatorSelection.setNextSelectionBlock(nextSelectionBlock);
        vm.stopPrank();
        
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator2.addr).checked_write(95);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator3.addr).checked_write(95);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator4.addr).checked_write(95);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator5.addr).checked_write(95);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator6).checked_write(95);
        
        vm.roll(nextSelectionBlock);
        vm.prank(sender);
        validatorSelection.monitorsValidators();
        
        assertFalse(validatorSelection.isOperationalValidator(validator1.addr));
        assertTrue(validatorSelection.isOperationalValidator(validator2.addr));
        assertEq(validatorSelection.getOperationalValidatorsCount(), 5);
    }

    function test_ConfigurationLimitsAreEnforced() public {
        vm.startPrank(address(governanceMock));
        
        vm.expectRevert();
        validatorSelection.setBlocksBetweenSelection(5);
        
        vm.expectRevert();
        validatorSelection.setBlocksBetweenSelection(200000);
        
        vm.expectRevert();
        validatorSelection.setBlocksWithoutProposeThreshold(5);
        
        vm.expectRevert();
        validatorSelection.setBlocksWithoutProposeThreshold(2000000);
        
        vm.expectRevert();
        validatorSelection.setBatchSize(5);
        
        vm.expectRevert();
        validatorSelection.setBatchSize(600);
        
        vm.stopPrank();
    }

    function test_NextSelectionBlockCannotBeInPast() public {
        vm.roll(500);
        
        vm.prank(address(governanceMock));
        vm.expectRevert();
        validatorSelection.setNextSelectionBlock(400);
    }

    function test_EventsAreEmittedCorrectly() public {
        vm.startPrank(address(governanceMock));
        
        address newValidator = address(0x777);
        
        vm.expectEmit(true, true, true, true);
        emit EligibleValidatorAdded(newValidator);
        validatorSelection.addEligibleValidator(newValidator);

        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorAdded(newValidator, block.number);
        validatorSelection.addOperationalValidator(newValidator);

        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorRemoved(newValidator, address(governanceMock));
        validatorSelection.removeOperationalValidator(newValidator);
        
        vm.stopPrank();
    }
}
