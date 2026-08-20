// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, Vm, console, stdStorage, StdStorage} from "lib/forge-std/src/Test.sol";
import {ValidatorSelection} from "src/ValidatorSelection.sol";
import {OperationMode, IValidatorSelection} from "src/interfaces/IValidatorSelection.sol";
import {AdminMock} from "test/mocks/AdminMock.sol";
import {GovernanceMock} from "test/mocks/GovernanceMock.sol";
import {NodeRulesV2Mock} from "test/mocks/NodeRulesV2Mock.sol";
import {AccountRulesV2Mock, GLOBAL_ADMIN_ROLE} from "test/mocks/AccountRulesV2Mock.sol";
import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";

contract ValidatorSelectionTest is Test {
    using stdStorage for StdStorage;

    ValidatorSelection validatorSelection;
    GovernanceMock governanceMock;
    AdminMock adminMock;
    NodeRulesV2Mock nodeRulesMock;
    AccountRulesV2Mock accountRulesMock;

    address sender = address(0x123);

    Vm.Wallet validator1 = vm.createWallet(1);
    Vm.Wallet validator2 = vm.createWallet(2);
    Vm.Wallet validator3 = vm.createWallet(3);
    Vm.Wallet validator4 = vm.createWallet(4);
    Vm.Wallet validator5 = vm.createWallet(5);
    Vm.Wallet validator6 = vm.createWallet(6);
    Vm.Wallet validator7 = vm.createWallet(7);
    Vm.Wallet validator8 = vm.createWallet(8);

    uint256 public initialNextSelectionBlock = 10;
    uint256 public initialBlocksBetweenSelection = 2;
    uint256 public initialBlocksWithoutProposeThreshold = 10;

    event MonitorExecuted(address indexed executor, uint256 indexed blockNumber);
    event SelectionExecuted(address[] operationalValidators);
    event OperationModeChanged(OperationMode indexed mode);
    event OperationalValidatorAdded(address indexed validator);
    event OperationalValidatorRemoved(address indexed validator);
    event OperationalValidatorManuallyRemoved(address indexed validator);
    event EligibleValidatorAdded(address indexed validator, bool indexed activateAsOperational);
    event EligibleValidatorRemoved(address indexed validator);
    event SelectionParametersUpdated(uint256 blocksBetweenSelection, uint256 blocksWithoutProposeThreshold);
    event AdminContractUpdated(address indexed oldAdmin, address indexed newAdmin);
    event AccountsContractUpdated(address indexed oldAccounts, address indexed newAccounts);
    event NodesContractUpdated(address indexed oldNodes, address indexed newNodes);

    error InvalidAddress();
    error SameAddress(address current);
    error InvalidAdminContract(address addr);
    error InvalidAccountsContract(address addr);
    error InvalidNodesContract(address addr);
    error UnauthorizedAccess(address account);
    error InvalidBlocksBetweenSelection();
    error InvalidBlocksWithoutProposeThreshold();
    error InvalidValidatorAddress(address nodeAddress);
    error NotEligibleNode(address nodeAddress);
    error AlreadyEligibleNode(address nodeAddress);
    error NotOperationalNode(address nodeAddress);
    error AlreadyOperationalNode(address nodeAddress);
    error FewOperationalValidators();
    error NotLocalNode(bytes32 enodeHigh, bytes32 enodeLow);
    error InactiveAccount(address account);
    error InvalidOperationMode();
    error FewEligibleValidators();

    function setUp() public {
        adminMock = new AdminMock();
        accountRulesMock = new AccountRulesV2Mock();
        nodeRulesMock = new NodeRulesV2Mock();

        validatorSelection = new ValidatorSelection(
            adminMock,
            accountRulesMock,
            nodeRulesMock,
            _initialEligibleValidators(),
            initialBlocksBetweenSelection,
            initialBlocksWithoutProposeThreshold,
            initialNextSelectionBlock
        );

        governanceMock = new GovernanceMock(address(validatorSelection));
        adminMock.addAdmin(address(governanceMock));

        console.log("ValidatorSelection:", address(validatorSelection));
        console.log("GovernanceMock:", address(governanceMock));
        console.log("AdminMock:", address(adminMock));
    }

    function _initialEligibleValidators() internal view returns (address[] memory) {
        address[] memory initialEligibleValidators = new address[](5);
        initialEligibleValidators[0] = validator1.addr;
        initialEligibleValidators[1] = validator2.addr;
        initialEligibleValidators[2] = validator3.addr;
        initialEligibleValidators[3] = validator4.addr;
        initialEligibleValidators[4] = validator5.addr;
        return initialEligibleValidators;
    }

    function _initialOperationalAddresses() internal view returns (address[] memory) {
        address[] memory addrs = new address[](5);
        addrs[0] = validator1.addr;
        addrs[1] = validator2.addr;
        addrs[2] = validator3.addr;
        addrs[3] = validator4.addr;
        addrs[4] = validator5.addr;
        return addrs;
    }

    function _enableAutomaticMode() internal {
        vm.prank(address(governanceMock));
        validatorSelection.setOperationMode(OperationMode.Automatic);
    }

    function _closeCurrentCycle(uint256 blockNumber) internal {
        assertGe(blockNumber, validatorSelection.nextSelectionBlock());
        vm.roll(blockNumber);
        vm.prank(sender);
        validatorSelection.executeMonitoring();
        assertEq(validatorSelection.getProtectedValidators().length, 0);
    }

    function _setLastBlockProposedBy(address validator, uint256 blockNumber) internal {
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector)
            .with_key(validator).checked_write(blockNumber);
        assertEq(validatorSelection.lastBlockProposedBy(validator), blockNumber);
    }

    function _mockNodeFromOrganization(uint256 orgId) internal {
        nodeRulesMock.setNode(INodeRulesV2.NodeType.Validator, "mock", orgId, true);
    }

    function test_getValidators() public {
        address[] memory active = validatorSelection.getValidators();
        assertEq(active.length, 5);
    }

    function test_getEligibleValidators() public {
        address[] memory eligible = validatorSelection.getEligibleValidators();
        assertEq(eligible.length, 5);
        assertEq(eligible[0], validator1.addr);
        assertEq(eligible[1], validator2.addr);
        assertEq(eligible[2], validator3.addr);
        assertEq(eligible[3], validator4.addr);
        assertEq(eligible[4], validator5.addr);
    }

    function test_getEligibleValidators_AnyAccountCanQuery() public {
        Vm.Wallet memory anyAccount = vm.createWallet(1234);
        vm.prank(anyAccount.addr);
        address[] memory eligible = validatorSelection.getEligibleValidators();
        assertEq(eligible.length, 5);
    }

    function test_getProtectedValidators() public {
        assertEq(validatorSelection.getProtectedValidators().length, 5);

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
        assertTrue(validatorSelection.isEligible(validator1.addr), "validador inicial deve ser elegivel");
        assertTrue(validatorSelection.isOperational(validator1.addr), "validador inicial deve ser operacional");
        assertTrue(validatorSelection.isProtected(validator1.addr), "validador inicial deve ser protegido");

        Vm.Wallet memory naoValidador = vm.createWallet(9999);
        assertFalse(validatorSelection.isEligible(naoValidador.addr), "endereco aleatorio nao deve ser elegivel");
        assertFalse(validatorSelection.isOperational(naoValidador.addr), "endereco aleatorio nao deve ser operacional");
        assertFalse(validatorSelection.isProtected(naoValidador.addr), "endereco aleatorio nao deve ser protegido");
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
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.setOperationMode(OperationMode.Automatic);
    }

    function test_setOperationMode_RevertsIfInvalidMode() public {
        vm.prank(address(governanceMock));
        vm.expectRevert(InvalidOperationMode.selector);
        
        (bool success,) = address(validatorSelection).call(
            abi.encodeWithSignature("setOperationMode(uint8)", uint8(2))
        );
        assertFalse(success, "Invalid mode should have reverted");
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

        uint256 blocksBetweenSelection = validatorSelection.blocksBetweenSelection();
        assertEq(validatorSelection.nextSelectionBlock(), blockNumber + blocksBetweenSelection);
        assertEq(validatorSelection.cycleStartBlock(), blockNumber);
    }

    function test_executeMonitoringWithMultipleCalls() public {
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

        uint256 blocksBetweenSelection = validatorSelection.blocksBetweenSelection();
        uint256 expectedNextSelectionBlock = blockNumber + blocksBetweenSelection;
        assertEq(validatorSelection.nextSelectionBlock(), expectedNextSelectionBlock);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit MonitorExecuted(sender, block.number);
        validatorSelection.executeMonitoring();
        assertEq(validatorSelection.nextSelectionBlock(), expectedNextSelectionBlock);
    }

    function test_executeMonitoringWithoutSelection() public {
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

    function test_executeMonitoringWithSelection() public {
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
        uint256 activeValidatorsLength = activeValidators.length;
        for (uint256 i; i < activeValidatorsLength; i++) {
            assertNotEq(activeValidators[i], validator1.addr);
        }

        assertEq(validatorSelection.getEligibleValidators().length, 5);

        uint256 expectedNextSelectionBlock = nextSelectionBlock + initialBlocksBetweenSelection;
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

    function test_executeMonitoring_RemovesUpToMinimumValidators() public {
        _enableAutomaticMode();

        _closeCurrentCycle(10);

        uint256 nextSelectionBlock = 100;

        _setLastBlockProposedBy(validator3.addr, nextSelectionBlock - 2);
        _setLastBlockProposedBy(validator4.addr, nextSelectionBlock - 3);
        _setLastBlockProposedBy(validator5.addr, nextSelectionBlock - 4);

        vm.coinbase(sender);
        vm.roll(nextSelectionBlock);

        vm.prank(sender);
        validatorSelection.executeMonitoring();

        address[] memory activeValidators = validatorSelection.getValidators();
        assertEq(activeValidators.length, 4);
        bool validator2Kept;
        for (uint256 i; i < activeValidators.length; i++) {
            assertNotEq(activeValidators[i], validator1.addr);
            if (activeValidators[i] == validator2.addr) validator2Kept = true;
        }
        assertTrue(validator2Kept);
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
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.setSelectionParameters(10, 100);
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

    function test_addOperationalValidator_RevertsIfAlreadyOperational() public {
        vm.startPrank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator6.addr, false);
        validatorSelection.addOperationalValidatorByAddress(validator6.addr);

        bytes memory expectedError = abi.encodeWithSelector(AlreadyOperationalNode.selector, validator6.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.addOperationalValidatorByAddress(validator6.addr);
        vm.stopPrank();
    }

    function test_addOperationalValidator_RevertsIfNotGovernance() public {
        Vm.Wallet memory notGovernance = vm.createWallet(1234);
        vm.prank(notGovernance.addr);
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.addOperationalValidatorByAddress(validator1.addr);
    }

    function test_addOperationalValidatorByAddress_RevertsIfZeroAddress() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(NotEligibleNode.selector, address(0));
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.addOperationalValidatorByAddress(address(0));
    }

    function test_addOperationalValidator_ByAdminOfSameOrganization() public {
        (bytes32 enodeHigh, bytes32 enodeLow) = (bytes32(uint256(1)), bytes32(uint256(2)));
        address validator = address(uint160(uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))));

        vm.prank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator, false);

        accountRulesMock.setRole(GLOBAL_ADMIN_ROLE, sender, true);
        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorAdded(validator);
        validatorSelection.addOperationalValidator(enodeHigh, enodeLow);

        address[] memory active = validatorSelection.getValidators();
        assertEq(active.length, 6);
        assertEq(active[5], validator);
    }

    function test_addOperationalValidator_RevertsIfInactiveAccount() public {
        (bytes32 enodeHigh, bytes32 enodeLow) = (bytes32(uint256(1)), bytes32(uint256(2)));

        accountRulesMock.setRole(GLOBAL_ADMIN_ROLE, sender, true);
        accountRulesMock.setAccountActive(sender, false);

        vm.prank(sender);
        bytes memory expectedError = abi.encodeWithSelector(InactiveAccount.selector, sender);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.addOperationalValidator(enodeHigh, enodeLow);
    }

    function test_addOperationalValidator_ByGovernanceOfAnyOrganization() public {
        (bytes32 enodeHigh, bytes32 enodeLow) = (bytes32(uint256(1)), bytes32(uint256(2)));
        address validator = address(uint160(uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))));

        vm.prank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator, false);

        _mockNodeFromOrganization(2);

        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorAdded(validator);
        validatorSelection.addOperationalValidator(enodeHigh, enodeLow);

        address[] memory active = validatorSelection.getValidators();
        assertEq(active.length, 6);
        assertEq(active[5], validator);
    }

    function test_addOperationalValidator_RevertsIfAdminOfDifferentOrganization() public {
        (bytes32 enodeHigh, bytes32 enodeLow) = (bytes32(uint256(1)), bytes32(uint256(2)));
        address validator = address(uint160(uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))));

        vm.prank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator, false);

        _mockNodeFromOrganization(2);

        accountRulesMock.setRole(GLOBAL_ADMIN_ROLE, sender, true);
        vm.prank(sender);
        bytes memory expectedError = abi.encodeWithSelector(NotLocalNode.selector, enodeHigh, enodeLow);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.addOperationalValidator(enodeHigh, enodeLow);
    }

    function test_addOperationalValidator_RevertsIfNotAdminNorGovernance() public {
        (bytes32 enodeHigh, bytes32 enodeLow) = (bytes32(uint256(1)), bytes32(uint256(2)));

        vm.prank(sender);
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, sender);
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
        Vm.Wallet memory notOperational = vm.createWallet(9999);

        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(NotOperationalNode.selector, notOperational.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.removeOperationalValidatorByAddress(notOperational.addr);
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
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.removeOperationalValidatorByAddress(validator1.addr);
    }

    function test_removeOperationalValidator_ByAdminOfSameOrganization() public {
        (bytes32 enodeHigh, bytes32 enodeLow) = (bytes32(uint256(1)), bytes32(uint256(2)));
        address validator = address(uint160(uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))));

        vm.startPrank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator, false);
        validatorSelection.addOperationalValidatorByAddress(validator);
        validatorSelection.removeOperationalValidatorByAddress(validator5.addr);
        vm.stopPrank();
        assertEq(validatorSelection.getValidators().length, 5);

        accountRulesMock.setRole(GLOBAL_ADMIN_ROLE, sender, true);
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
        (bytes32 enodeHigh, bytes32 enodeLow) = (bytes32(uint256(1)), bytes32(uint256(2)));
        address validator = address(uint160(uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))));

        vm.startPrank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator, false);
        validatorSelection.addOperationalValidatorByAddress(validator);
        validatorSelection.removeOperationalValidatorByAddress(validator3.addr);
        validatorSelection.removeOperationalValidatorByAddress(validator4.addr);
        validatorSelection.removeOperationalValidatorByAddress(validator5.addr);
        vm.stopPrank();

        accountRulesMock.setRole(GLOBAL_ADMIN_ROLE, sender, true);
        vm.prank(sender);
        bytes memory expectedError = abi.encodeWithSelector(FewOperationalValidators.selector);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.removeOperationalValidatorByAdmin(enodeHigh, enodeLow);
    }

    function test_removeOperationalValidator_ByGovernanceViaEnode() public {
        (bytes32 enodeHigh, bytes32 enodeLow) = (bytes32(uint256(1)), bytes32(uint256(2)));
        address validator = address(uint160(uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))));

        vm.startPrank(address(governanceMock));
        validatorSelection.addEligibleValidatorByAddress(validator, false);
        validatorSelection.addOperationalValidatorByAddress(validator);

        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorManuallyRemoved(validator);
        validatorSelection.removeOperationalValidator(enodeHigh, enodeLow);
        vm.stopPrank();

        address[] memory active = validatorSelection.getValidators();
        assertEq(active.length, 5);
    }

    function test_addEligibleValidator() public {
        Vm.Wallet memory newValidator = vm.createWallet(6);

        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit EligibleValidatorAdded(newValidator.addr, false);
        validatorSelection.addEligibleValidatorByAddress(newValidator.addr, false);

        assertEq(validatorSelection.getEligibleValidators().length, 6);
        assertEq(validatorSelection.getValidators().length, 5);
        assertEq(validatorSelection.getProtectedValidators().length, 5);
    }

    function test_addEligibleValidator_WithOperationalActivation() public {
        Vm.Wallet memory newValidator = vm.createWallet(6);

        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit EligibleValidatorAdded(newValidator.addr, true);
        vm.expectEmit(true, true, true, true);
        emit OperationalValidatorAdded(newValidator.addr);
        validatorSelection.addEligibleValidatorByAddress(newValidator.addr, true);

        assertEq(validatorSelection.getEligibleValidators().length, 6);
        address[] memory active = validatorSelection.getValidators();
        assertEq(active.length, 6);
        assertEq(active[5], newValidator.addr);
        address[] memory added = validatorSelection.getProtectedValidators();
        assertEq(added.length, 6);
        assertEq(added[5], newValidator.addr);
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
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.addEligibleValidatorByAddress(vm.createWallet(6).addr, false);
    }

    function test_addEligibleValidator_AdjustsBlocksWithoutProposeThreshold() public {
        vm.startPrank(address(governanceMock));
        validatorSelection.setSelectionParameters(initialBlocksBetweenSelection, 5);

        Vm.Wallet memory newValidator = vm.createWallet(6);
        vm.expectEmit(true, true, true, true);
        emit SelectionParametersUpdated(initialBlocksBetweenSelection, 6);
        validatorSelection.addEligibleValidatorByAddress(newValidator.addr, false);
        vm.stopPrank();

        assertEq(validatorSelection.blocksWithoutProposeThreshold(), 6);
    }

    function test_addEligibleValidator_ViaEnode() public {
        (bytes32 enodeHigh, bytes32 enodeLow) = (bytes32(uint256(1)), bytes32(uint256(2)));
        address validator = address(uint160(uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))));

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
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.removeEligibleValidatorByAddress(validator1.addr);
    }

    function test_removeEligibleValidator_ViaEnode() public {
        (bytes32 enodeHigh, bytes32 enodeLow) = (bytes32(uint256(1)), bytes32(uint256(2)));
        address validator = address(uint160(uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))));

        vm.startPrank(address(governanceMock));
        validatorSelection.addEligibleValidator(enodeHigh, enodeLow, false);
        assertEq(validatorSelection.getEligibleValidators().length, 6);

        vm.expectEmit(true, true, true, true);
        emit EligibleValidatorRemoved(validator);
        validatorSelection.removeEligibleValidator(enodeHigh, enodeLow);
        vm.stopPrank();

        assertEq(validatorSelection.getEligibleValidators().length, 5);
    }

    function _getEnodeHighLow(Vm.Wallet memory _wallet) public pure returns (uint256, uint256) {
        uint256 enodeHigh = _wallet.publicKeyX;
        uint256 enodeLow = _wallet.publicKeyX;
        return (enodeHigh, enodeLow);
    }

    function test_supportsInterface() public {
        assertTrue(validatorSelection.supportsInterface(0x01ffc9a7));
        assertTrue(validatorSelection.supportsInterface(type(IValidatorSelection).interfaceId));
        assertFalse(validatorSelection.supportsInterface(0xffffffff));
    }

    function test_updateAdminContract() public {
        AdminMock newAdminMock = new AdminMock();

        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit AdminContractUpdated(address(adminMock), address(newAdminMock));
        validatorSelection.updateAdminContract(address(newAdminMock));

        assertEq(address(validatorSelection.admins()), address(newAdminMock));

        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, address(governanceMock));
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.setOperationMode(OperationMode.Automatic);

        validatorSelection.setOperationMode(OperationMode.Automatic);
        assertEq(uint256(validatorSelection.operationMode()), uint256(OperationMode.Automatic));
    }

    function test_updateAdminContract_RevertsIfNotGovernance() public {
        Vm.Wallet memory notGovernance = vm.createWallet(1234);
        vm.prank(notGovernance.addr);
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.updateAdminContract(address(adminMock));
    }

    function test_updateAdminContract_RevertsIfZeroAddress() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidAddress.selector);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.updateAdminContract(address(0));
    }

    function test_updateAdminContract_RevertsIfSameAddress() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(SameAddress.selector, address(adminMock));
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.updateAdminContract(address(adminMock));
    }

    function test_updateAdminContract_RevertsIfInvalidContract() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidAdminContract.selector, address(accountRulesMock));
        vm.expectRevert(expectedError);
        validatorSelection.updateAdminContract(address(accountRulesMock));
    }

    function test_updateAdminContract_RevertsIfZeroAddressIsAuthorized() public {
        AdminMock newAdminMock = new AdminMock();
        newAdminMock.addAdmin(address(0));

        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidAdminContract.selector, address(newAdminMock));
        vm.expectRevert(expectedError);
        validatorSelection.updateAdminContract(address(newAdminMock));
    }

    function test_updateAccountsContract() public {
        AccountRulesV2Mock newAccountRulesMock = new AccountRulesV2Mock();

        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit AccountsContractUpdated(address(accountRulesMock), address(newAccountRulesMock));
        validatorSelection.updateAccountsContract(address(newAccountRulesMock));

        assertEq(address(validatorSelection.accountsContract()), address(newAccountRulesMock));
    }

    function test_updateAccountsContract_RevertsIfNotGovernance() public {
        Vm.Wallet memory notGovernance = vm.createWallet(1234);
        vm.prank(notGovernance.addr);
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.updateAccountsContract(address(accountRulesMock));
    }

    function test_updateAccountsContract_RevertsIfZeroAddress() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidAddress.selector);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.updateAccountsContract(address(0));
    }

    function test_updateAccountsContract_RevertsIfSameAddress() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(SameAddress.selector, address(accountRulesMock));
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.updateAccountsContract(address(accountRulesMock));
    }

    function test_updateAccountsContract_RevertsIfInvalidContract() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidAccountsContract.selector, address(adminMock));
        vm.expectRevert(expectedError);
        validatorSelection.updateAccountsContract(address(adminMock));
    }

    function test_updateAccountsContract_RevertsIfZeroAddressIsActive() public {
        AccountRulesV2Mock newAccountRulesMock = new AccountRulesV2Mock();
        newAccountRulesMock.setAccountActive(address(0), true);

        vm.prank(address(governanceMock));
        bytes memory expectedError =
            abi.encodeWithSelector(InvalidAccountsContract.selector, address(newAccountRulesMock));
        vm.expectRevert(expectedError);
        validatorSelection.updateAccountsContract(address(newAccountRulesMock));
    }

    function test_updateNodesContract() public {
        NodeRulesV2Mock newNodeRulesMock = new NodeRulesV2Mock();

        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit NodesContractUpdated(address(nodeRulesMock), address(newNodeRulesMock));
        validatorSelection.updateNodesContract(address(newNodeRulesMock));

        assertEq(address(validatorSelection.nodesContract()), address(newNodeRulesMock));
    }

    function test_updateNodesContract_RevertsIfNotGovernance() public {
        Vm.Wallet memory notGovernance = vm.createWallet(1234);
        vm.prank(notGovernance.addr);
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance.addr);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.updateNodesContract(address(nodeRulesMock));
    }

    function test_updateNodesContract_RevertsIfZeroAddress() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidAddress.selector);
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.updateNodesContract(address(0));
    }

    function test_updateNodesContract_RevertsIfSameAddress() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(SameAddress.selector, address(nodeRulesMock));
        vm.expectRevert(expectedError, address(validatorSelection));
        validatorSelection.updateNodesContract(address(nodeRulesMock));
    }

    function test_updateNodesContract_RevertsIfInvalidContract() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidNodesContract.selector, address(adminMock));
        vm.expectRevert(expectedError);
        validatorSelection.updateNodesContract(address(adminMock));
    }

    function test_updateNodesContract_RevertsIfZeroKeyNodeExists() public {
        NodeRulesV2Mock newNodeRulesMock = new NodeRulesV2Mock();
        newNodeRulesMock.setNodeOverride(0, INodeRulesV2.NodeType.Validator, "mock", 1, true);

        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidNodesContract.selector, address(newNodeRulesMock));
        vm.expectRevert(expectedError);
        validatorSelection.updateNodesContract(address(newNodeRulesMock));
    }
}
