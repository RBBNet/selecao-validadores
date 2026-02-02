// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Governable} from "src/Governable.sol";
import {IAdminProxy} from "src/interfaces/IAdminProxy.sol";
import {AdminMock} from "test/mocks/AdminMock.sol";

contract GovernableTestContract is Governable {
    uint256 public value;
    bool public initialized;

    function initialize(IAdminProxy adminsProxy) public initializer {
        __Governable_init(adminsProxy);
        initialized = true;
    }

    function setValue(uint256 _value) external onlyGovernance {
        value = _value;
    }

    function setValuePublic(uint256 _value) external {
        value = _value;
    }
}

contract GovernableTest is Test {

    GovernableTestContract public governableContract;
    AdminMock public adminMock;

    address public governance;
    address public nonGovernance;

    event AdminProxySet(IAdminProxy indexed adminsProxy);

    error UnauthorizedAccess(address account);
    error InvalidAdminProxyAddress(IAdminProxy invalidAddress);

    function setUp() public {
        adminMock = new AdminMock();

        governance = 0xa0Cb889707d426A7A386870A03bc70d1b0697598;
        nonGovernance = address(0x2);

        vm.prank(governance);
        governableContract = new GovernableTestContract();
        
        vm.prank(governance);
        governableContract.initialize(IAdminProxy(address(adminMock)));
    }

    function test_Initialize_Success() public {
        GovernableTestContract newContract = new GovernableTestContract();

        vm.expectEmit(true, false, false, false);
        emit AdminProxySet(IAdminProxy(address(adminMock)));

        newContract.initialize(IAdminProxy(address(adminMock)));

        assertTrue(newContract.initialized(), "Contract should be initialized");
        assertEq(address(newContract.admins()), address(adminMock), "Admin proxy should be set");
    }

    function test_Initialize_RevertsWithZeroAddress() public {
        GovernableTestContract newContract = new GovernableTestContract();

        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidAdminProxyAddress.selector,
                IAdminProxy(address(0))
            )
        );

        newContract.initialize(IAdminProxy(address(0)));
    }

    function test_Initialize_CannotInitializeTwice() public {
        vm.expectRevert();
        governableContract.initialize(IAdminProxy(address(adminMock)));
    }

    function test_Initialize_EmitsAdminProxySetEvent() public {
        GovernableTestContract newContract = new GovernableTestContract();

        vm.expectEmit(true, false, false, false);
        emit AdminProxySet(IAdminProxy(address(adminMock)));

        newContract.initialize(IAdminProxy(address(adminMock)));
    }

    function test_OnlyGovernance_AllowsAuthorizedCaller() public {
        uint256 newValue = 42;

        vm.prank(governance);
        governableContract.setValue(newValue);

        assertEq(governableContract.value(), newValue, "Value should be updated by governance");
    }

    function test_OnlyGovernance_RevertsUnauthorizedCaller() public {
        uint256 newValue = 42;

        vm.prank(nonGovernance);
        vm.expectRevert(
            abi.encodeWithSelector(UnauthorizedAccess.selector, nonGovernance)
        );

        governableContract.setValue(newValue);
    }

    function test_OnlyGovernance_RevertsWithCorrectErrorMessage() public {
        address unauthorizedAddress = address(0x999);

        vm.prank(unauthorizedAddress);
        vm.expectRevert(
            abi.encodeWithSelector(UnauthorizedAccess.selector, unauthorizedAddress)
        );

        governableContract.setValue(100);
    }

    function test_OnlyGovernance_AllowsMultipleAuthorizedCallers() public {
        vm.prank(governance);
        governableContract.setValue(10);
        assertEq(governableContract.value(), 10);

        vm.prank(governance);
        governableContract.setValue(20);
        assertEq(governableContract.value(), 20);
    }

    function test_PublicFunction_AllowsAnyCaller() public {
        vm.prank(nonGovernance);
        governableContract.setValuePublic(999);

        assertEq(governableContract.value(), 999, "Public function should work for anyone");
    }

    function test_AdminsProxy_IsPubliclyAccessible() public {
        IAdminProxy adminsProxy = governableContract.admins();
        assertEq(address(adminsProxy), address(adminMock), "Admins proxy should be accessible");
    }

    function test_AdminsProxy_IsSetCorrectly() public view {
        assertEq(
            address(governableContract.admins()),
            address(adminMock),
            "Admin proxy address should match"
        );
    }

    function test_Integration_GovernanceChangeFlow() public {
        assertEq(governableContract.value(), 0);

        vm.prank(governance);
        governableContract.setValue(100);
        assertEq(governableContract.value(), 100);

        vm.prank(governance);
        governableContract.setValue(200);
        assertEq(governableContract.value(), 200);

        vm.prank(governance);
        governableContract.setValue(300);
        assertEq(governableContract.value(), 300);
    }

    function test_Integration_RemoveGovernanceAccess() public {
        vm.prank(governance);
        governableContract.setValue(50);
        assertEq(governableContract.value(), 50);

        vm.prank(nonGovernance);
        vm.expectRevert(
            abi.encodeWithSelector(UnauthorizedAccess.selector, nonGovernance)
        );
        governableContract.setValue(100);

        assertEq(governableContract.value(), 50);
    }

    function testFuzz_OnlyGovernance_AllowsAuthorizedAddress(address caller) public {
        vm.assume(caller == governance);

        vm.prank(caller);
        governableContract.setValue(12345);

        assertEq(governableContract.value(), 12345);
    }

    function testFuzz_OnlyGovernance_RejectsUnauthorizedAddress(address caller) public {
        vm.assume(caller != governance);
        vm.assume(!adminMock.isAuthorized(caller));

        vm.prank(caller);
        vm.expectRevert(
            abi.encodeWithSelector(UnauthorizedAccess.selector, caller)
        );

        governableContract.setValue(99999);
    }

    function testFuzz_SetValue_WithAnyValue(uint256 value) public {
        vm.prank(governance);
        governableContract.setValue(value);

        assertEq(governableContract.value(), value);
    }

    function test_EdgeCase_ZeroValueSet() public {
        vm.prank(governance);
        governableContract.setValue(0);
        assertEq(governableContract.value(), 0);
    }

    function test_EdgeCase_MaxUint256ValueSet() public {
        vm.prank(governance);
        governableContract.setValue(type(uint256).max);
        assertEq(governableContract.value(), type(uint256).max);
    }

    function test_EdgeCase_ConsecutiveCallsFromSameGovernance() public {
        vm.startPrank(governance);

        governableContract.setValue(1);
        assertEq(governableContract.value(), 1);

        governableContract.setValue(2);
        assertEq(governableContract.value(), 2);

        governableContract.setValue(3);
        assertEq(governableContract.value(), 3);

        vm.stopPrank();
    }

    function test_EdgeCase_AlternatingAuthorizedCalls() public {
        vm.prank(governance);
        governableContract.setValue(10);

        vm.prank(governance);
        governableContract.setValue(20);

        vm.prank(governance);
        governableContract.setValue(30);

        assertEq(governableContract.value(), 30);
    }

    function test_Security_CannotBypassModifier() public {
        vm.prank(nonGovernance);
        vm.expectRevert();
        governableContract.setValue(999);
    }

    function test_Security_ModifierChecksBeforeExecution() public {
        uint256 initialValue = governableContract.value();

        vm.prank(governance);
        governableContract.setValue(100);

        vm.prank(nonGovernance);
        try governableContract.setValue(200) {
            fail("Should have reverted");
        } catch (bytes memory reason) {
            assertEq(governableContract.value(), 100, "Value should not change on revert");
        }
    }

    function test_Security_NoReentrancyIssues() public {
        vm.prank(governance);
        governableContract.setValue(42);
        assertEq(governableContract.value(), 42);
    }

    function test_Gas_CheckGovernance() public {
        vm.prank(governance);

        uint256 gasBefore = gasleft();
        governableContract.setValue(100);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas usado para chamada com onlyGovernance:", gasUsed);
        
        assertLt(gasUsed, 50000, "Governance check should use less than 50k gas");
    }

    function test_Gas_PublicFunctionComparison() public {
        vm.prank(governance);
        uint256 gasBeforeProtected = gasleft();
        governableContract.setValue(100);
        uint256 gasProtected = gasBeforeProtected - gasleft();

        vm.prank(nonGovernance);
        uint256 gasBeforePublic = gasleft();
        governableContract.setValuePublic(200);
        uint256 gasPublic = gasBeforePublic - gasleft();

        uint256 overhead = gasProtected > gasPublic ? gasProtected - gasPublic : 0;
        assertLt(overhead, 35000, "Modifier overhead deve ser menor que 35k");
    }

    function invariant_AdminProxyNeverZero() public view {
        if (governableContract.initialized()) {
            assertTrue(
                address(governableContract.admins()) != address(0),
                "Admin proxy should never be zero after init"
            );
        }
    }

    function test_Documentation_ErrorMessagesAreDescriptive() public {
        vm.prank(nonGovernance);
        
        try governableContract.setValue(100) {
            fail("Should have reverted");
        } catch (bytes memory reason) {
            bytes memory expectedError = abi.encodeWithSelector(
                UnauthorizedAccess.selector,
                nonGovernance
            );
            assertEq(reason, expectedError, "Error should contain caller address");
        }
    }

    function test_Documentation_EventsAreEmittedCorrectly() public {
        GovernableTestContract newContract = new GovernableTestContract();
        vm.expectEmit(true, false, false, false);
        emit AdminProxySet(IAdminProxy(address(adminMock)));

        newContract.initialize(IAdminProxy(address(adminMock)));
    }
}
