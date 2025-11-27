// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, Vm, console} from "lib/forge-std/src/Test.sol";
import {Upgrades} from "lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";
import {ValidatorSelection} from "src/ValidatorSelection.sol";
import {AdminMock} from "test/mocks/AdminMock.sol";
import {GovernanceMock} from "test/mocks/GovernanceMock.sol";
import {NodeRulesV2Mock} from "test/mocks/NodeRulesV2Mock.sol";
import {AccountRulesV2Mock} from "test/mocks/AccountRulesV2Mock.sol";

contract ValidatorSelectionTest is Test {
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

    event MonitorExecuted(address indexed executor);
    event SelectionExecuted(address indexed executor);
    event ValidatorRemoved(address indexed removed);

    error MonitoringAlreadyExecuted();

    function setUp() public {
        adminMock = new AdminMock();
        accountRulesMock = new AccountRulesV2Mock();
        nodeRulesMock = new NodeRulesV2Mock();

        proxyContractAddress = Upgrades.deployUUPSProxy(
            "ValidatorSelection.sol",
            abi.encodeCall(ValidatorSelection.initialize, (adminMock, accountRulesMock, nodeRulesMock))
        );
        validatorSelection = ValidatorSelection(proxyContractAddress);
        governanceMock = new GovernanceMock(address(proxyContractAddress));
        adminMock.addAdmin(address(governanceMock));

        vm.startPrank(address(governanceMock));
        validatorSelection.setBlocksBetweenSelection(1);
        validatorSelection.setBlocksWithoutProposeThreshold(10);
        validatorSelection.addElegibleValidator(validator1.addr);
        validatorSelection.addElegibleValidator(validator2.addr);
        validatorSelection.addElegibleValidator(validator3.addr);
        vm.stopPrank();
    }

    function _getEnodeHighLow(Vm.Wallet memory _wallet) public pure returns (uint256, uint256) {
        uint256 enodeHigh = _wallet.publicKeyX;
        uint256 enodeLow = _wallet.publicKeyX;
        return (enodeHigh, enodeLow);
    }

    function test_setBlocksBetweenSelection() public {
        assertEq(validatorSelection.blocksBetweenSelection(), 1);
        vm.prank(address(governanceMock));
        validatorSelection.setBlocksBetweenSelection(10);
        assertEq(validatorSelection.blocksBetweenSelection(), 10);
    }

    function test_setBlocksWithoutProposeThreshold() public {
        assertEq(validatorSelection.blocksWithoutProposeThreshold(), 10);
        vm.prank(address(governanceMock));
        validatorSelection.setBlocksWithoutProposeThreshold(100);
        assertEq(validatorSelection.blocksWithoutProposeThreshold(), 100);
    }

    function test_getActiveValidators() public {
        address[] memory active = validatorSelection.getActiveValidators();
        assertEq(active.length, 0);
    }

    function test_monitorsValidators() public {
        Vm.Wallet memory proposer = validator1;
        vm.coinbase(proposer.addr);

        vm.prank(sender);
        vm.expectEmit(true, false, false, false);
        emit MonitorExecuted(sender);
        vm.expectEmit(true, false, false, false);
        emit SelectionExecuted(sender);
        validatorSelection.monitorsValidators();
        assertEq(validatorSelection.lastBlockProposedBy(proposer.addr), block.number);
    }

    function test_multipleCallsToMonitorsValidators() public {
        Vm.Wallet memory proposer = validator1;
        vm.coinbase(proposer.addr);

        vm.prank(sender);
        vm.expectEmit(true, false, false, false);
        emit MonitorExecuted(sender);
        vm.expectEmit(true, false, false, false);
        emit SelectionExecuted(sender);
        validatorSelection.monitorsValidators();

        vm.prank(sender);
        validatorSelection.addOperationalValidator(bytes32(proposer.publicKeyX), bytes32(proposer.publicKeyY));

        bytes4 expectedErrorSelector = MonitoringAlreadyExecuted.selector;
        vm.expectRevert(expectedErrorSelector);
        validatorSelection.monitorsValidators();
    }

    function test_selectValidatorsWithoutRemotion() public {
        Vm.Wallet memory proposer = validator1;
        vm.coinbase(proposer.addr);

        vm.prank(sender);
        vm.expectEmit(true, false, false, false);
        emit SelectionExecuted(sender);
        validatorSelection.monitorsValidators();
        validatorSelection.addOperationalValidator(bytes32(proposer.publicKeyX), bytes32(proposer.publicKeyY));
        assertEq(validatorSelection.lastBlockProposedBy(proposer.addr), block.number);
    }

    function test_selectValidatorsWithRemotion() public {
        Vm.Wallet memory proposer = validator1;
        vm.coinbase(proposer.addr);

        vm.prank(sender);
        vm.expectEmit(true, false, false, false);
        emit SelectionExecuted(sender);
        validatorSelection.monitorsValidators();
        validatorSelection.addOperationalValidator(bytes32(proposer.publicKeyX), bytes32(proposer.publicKeyY));
        assertEq(validatorSelection.lastBlockProposedBy(proposer.addr), block.number);

        vm.roll(block.number + validatorSelection.blocksWithoutProposeThreshold() + 1);

        proposer = validator2;
        vm.coinbase(proposer.addr);

        vm.prank(sender);
        vm.expectEmit(true, false, false, false);
        emit ValidatorRemoved(validator1.addr);
        vm.expectEmit(true, false, false, false);
        emit SelectionExecuted(sender);
        validatorSelection.monitorsValidators();
        validatorSelection.addOperationalValidator(bytes32(proposer.publicKeyX), bytes32(proposer.publicKeyY));
    }
}
