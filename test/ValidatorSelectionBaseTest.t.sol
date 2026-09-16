// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Test, Vm, stdStorage, StdStorage} from "lib/forge-std/src/Test.sol";
import {ValidatorSelection} from "src/ValidatorSelection.sol";
import {OperationMode} from "src/interfaces/IValidatorSelection.sol";
import {AdminMock} from "test/mocks/AdminMock.sol";
import {GovernanceMock} from "test/mocks/GovernanceMock.sol";
import {NodeRulesV2Mock} from "test/mocks/NodeRulesV2Mock.sol";
import {AccountRulesV2Mock} from "test/mocks/AccountRulesV2Mock.sol";
import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";
import {LOCAL_ADMIN_ROLE} from "src/interfaces/IAccountRulesV2.sol";

abstract contract ValidatorSelectionBaseTest is Test {
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
    error FewEligibleValidators();
    error FewOperationalValidators();
    error NotLocalNode(bytes32 enodeHigh, bytes32 enodeLow);
    error InactiveAccount(address account);
    error InvalidOperationMode();

    function setUp() public virtual {
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
    }

    function _expectRevertUnauthorized(address caller) internal {
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, caller);
        vm.expectRevert(expectedError, address(validatorSelection));
    }

    function _expectRevertInvalidAddress() internal {
        bytes memory expectedError = abi.encodeWithSelector(InvalidAddress.selector);
        vm.expectRevert(expectedError, address(validatorSelection));
    }

    function _expectRevertSameAddress(address current) internal {
        bytes memory expectedError = abi.encodeWithSelector(SameAddress.selector, current);
        vm.expectRevert(expectedError, address(validatorSelection));
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

    function _enableAutomaticMode() internal {
        vm.prank(address(governanceMock));
        validatorSelection.setOperationMode(OperationMode.Automatic);
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

    function _setSenderAsAdmin(uint256 orgId) internal {
        accountRulesMock.setRole(LOCAL_ADMIN_ROLE, sender, true);
        accountRulesMock.setAccount(sender, orgId, LOCAL_ADMIN_ROLE, true);
    }

    function _registerNode(bytes32 enodeHigh, bytes32 enodeLow, INodeRulesV2.NodeType nodeType, uint256 orgId, bool active)
        internal
    {
        uint256 nodeKey = uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)));
        nodeRulesMock.setNodeOverride(nodeKey, nodeType, "mock", orgId, active);
    }
}
