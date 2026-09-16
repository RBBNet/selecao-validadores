pragma solidity ^0.8.22;

import {Vm} from "lib/forge-std/src/Test.sol";
import {OperationMode} from "src/interfaces/IValidatorSelection.sol";
import {AdminMock} from "test/mocks/AdminMock.sol";
import {NodeRulesV2Mock} from "test/mocks/NodeRulesV2Mock.sol";
import {AccountRulesV2Mock} from "test/mocks/AccountRulesV2Mock.sol";
import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";
import {ValidatorSelectionBaseTest} from "test/ValidatorSelectionBaseTest.t.sol";

contract ValidatorSelectionGovernancaTest is ValidatorSelectionBaseTest {
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
        _expectRevertUnauthorized(notGovernance.addr);
        validatorSelection.updateAdminContract(address(adminMock));
    }

    function test_updateAdminContract_RevertsIfZeroAddress() public {
        vm.prank(address(governanceMock));
        _expectRevertInvalidAddress();
        validatorSelection.updateAdminContract(address(0));
    }

    function test_updateAdminContract_RevertsIfSameAddress() public {
        vm.prank(address(governanceMock));
        _expectRevertSameAddress(address(adminMock));
        validatorSelection.updateAdminContract(address(adminMock));
    }

    function test_updateAdminContract_RevertsIfInvalidContract() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidAdminContract.selector, address(accountRulesMock));
        vm.expectRevert(expectedError);
        validatorSelection.updateAdminContract(address(accountRulesMock));
    }

    function test_updateAdminContract_AcceptsContractWithZeroAddressAuthorized() public {
        AdminMock newAdminMock = new AdminMock();
        newAdminMock.addAdmin(address(0));

        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit AdminContractUpdated(address(adminMock), address(newAdminMock));
        validatorSelection.updateAdminContract(address(newAdminMock));

        assertEq(address(validatorSelection.admins()), address(newAdminMock));
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
        _expectRevertUnauthorized(notGovernance.addr);
        validatorSelection.updateAccountsContract(address(accountRulesMock));
    }

    function test_updateAccountsContract_RevertsIfZeroAddress() public {
        vm.prank(address(governanceMock));
        _expectRevertInvalidAddress();
        validatorSelection.updateAccountsContract(address(0));
    }

    function test_updateAccountsContract_RevertsIfSameAddress() public {
        vm.prank(address(governanceMock));
        _expectRevertSameAddress(address(accountRulesMock));
        validatorSelection.updateAccountsContract(address(accountRulesMock));
    }

    function test_updateAccountsContract_RevertsIfInvalidContract() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidAccountsContract.selector, address(adminMock));
        vm.expectRevert(expectedError);
        validatorSelection.updateAccountsContract(address(adminMock));
    }

    function test_updateAccountsContract_AcceptsContractWithZeroAddressActive() public {
        AccountRulesV2Mock newAccountRulesMock = new AccountRulesV2Mock();
        newAccountRulesMock.setAccountActive(address(0), true);

        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit AccountsContractUpdated(address(accountRulesMock), address(newAccountRulesMock));
        validatorSelection.updateAccountsContract(address(newAccountRulesMock));

        assertEq(address(validatorSelection.accountsContract()), address(newAccountRulesMock));
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
        _expectRevertUnauthorized(notGovernance.addr);
        validatorSelection.updateNodesContract(address(nodeRulesMock));
    }

    function test_updateNodesContract_RevertsIfZeroAddress() public {
        vm.prank(address(governanceMock));
        _expectRevertInvalidAddress();
        validatorSelection.updateNodesContract(address(0));
    }

    function test_updateNodesContract_RevertsIfSameAddress() public {
        vm.prank(address(governanceMock));
        _expectRevertSameAddress(address(nodeRulesMock));
        validatorSelection.updateNodesContract(address(nodeRulesMock));
    }

    function test_updateNodesContract_RevertsIfInvalidContract() public {
        vm.prank(address(governanceMock));
        bytes memory expectedError = abi.encodeWithSelector(InvalidNodesContract.selector, address(adminMock));
        vm.expectRevert(expectedError);
        validatorSelection.updateNodesContract(address(adminMock));
    }

    function test_updateNodesContract_AcceptsContractWithZeroKeyNode() public {
        NodeRulesV2Mock newNodeRulesMock = new NodeRulesV2Mock();
        newNodeRulesMock.setNodeOverride(0, INodeRulesV2.NodeType.Validator, "mock", 1, true);

        vm.prank(address(governanceMock));
        vm.expectEmit(true, true, true, true);
        emit NodesContractUpdated(address(nodeRulesMock), address(newNodeRulesMock));
        validatorSelection.updateNodesContract(address(newNodeRulesMock));

        assertEq(address(validatorSelection.nodesContract()), address(newNodeRulesMock));
    }
}
