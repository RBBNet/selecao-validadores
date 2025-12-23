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

    event MonitorExecuted();
    event SelectionExecuted();
    event ValidatorsRemoved(address[] removed);

    error MonitoringAlreadyExecuted();
    error UnauthorizedAccess(address account);
    error InvalidAdminProxyAddress(AdminMock invalidAddress);
    error NumberOfBlockBetweenSelectionIsZero();
    error NumberOfBlockWithoutProposeIsZero();

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

    function test_getActiveValidators() public {
        address[] memory active = validatorSelection.getActiveValidators();
        assertEq(active.length, 0);
    }

    function test_monitorsValidators() public {
        Vm.Wallet memory proposer = validator1;
        vm.roll(validatorSelection.nextSelectionBlock());
        vm.coinbase(proposer.addr);
        assertEq(validatorSelection.lastBlockProposedBy(proposer.addr), 0);

        uint256 blockNumber = block.number;
        assertEq(validatorSelection.nextSelectionBlock(), blockNumber);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit MonitorExecuted();
        vm.expectEmit(true, true, true, true);
        emit SelectionExecuted();
        validatorSelection.monitorsValidators();
        assertEq(validatorSelection.lastBlockProposedBy(proposer.addr), blockNumber);

        uint256 blocksBetweenSelection = validatorSelection.blocksBetweenSelection();
        assertEq(validatorSelection.nextSelectionBlock(), blockNumber + blocksBetweenSelection);
    }

    function test_monitorsValidatorsWithMultipleCalls() public {
        Vm.Wallet memory proposer = validator1;
        vm.roll(validatorSelection.nextSelectionBlock());
        vm.coinbase(proposer.addr);
        assertEq(validatorSelection.lastBlockProposedBy(proposer.addr), 0);

        uint256 blockNumber = block.number;
        assertEq(validatorSelection.nextSelectionBlock(), blockNumber);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit MonitorExecuted();
        vm.expectEmit(true, true, true, true);
        emit SelectionExecuted();
        validatorSelection.monitorsValidators();
        assertEq(validatorSelection.lastBlockProposedBy(proposer.addr), blockNumber);

        uint256 blocksBetweenSelection = validatorSelection.blocksBetweenSelection();
        uint256 expectedNextSelectionBlock = blockNumber + blocksBetweenSelection;
        assertEq(validatorSelection.nextSelectionBlock(), expectedNextSelectionBlock);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit MonitorExecuted();
        validatorSelection.monitorsValidators();
        assertEq(validatorSelection.nextSelectionBlock(), expectedNextSelectionBlock);
    }

    function test_monitorsValidatorsWithoutSelection() public {
        Vm.Wallet memory proposer = validator1;
        vm.coinbase(proposer.addr);
        assertEq(validatorSelection.lastBlockProposedBy(proposer.addr), 0);

        uint256 blockNumber = block.number;
        uint256 nextSelectionBlock = validatorSelection.nextSelectionBlock();
        assertNotEq(nextSelectionBlock, blockNumber);

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit MonitorExecuted();
        validatorSelection.monitorsValidators();
        assertEq(validatorSelection.nextSelectionBlock(), nextSelectionBlock);
    }

    function test_monitorsValidatorsWithSelection() public {
        // neste teste, temos 5 validadores operacionais. vamos fazer o monitoramento e esperamos
        // remover o validador1, que vamos definir para que ele fique um tempo sem propor novos blocos

        // setup
        vm.startPrank(address(governanceMock));
        validatorSelection.addOperationalValidator(validator1.addr);
        validatorSelection.addOperationalValidator(validator2.addr);
        validatorSelection.addOperationalValidator(validator3.addr);
        validatorSelection.addOperationalValidator(validator4.addr);
        validatorSelection.addOperationalValidator(validator5.addr);
        vm.stopPrank();
        assertEq(validatorSelection.getActiveValidators().length, 5);

        // garante que estamos no bloco 1
        assertEq(block.number, 1);

        // define o próximo bloco que vai ocorrer a seleção
        uint256 nextSelectionBlock = 100;
        vm.prank(address(governanceMock));
        validatorSelection.setNextSelectionBlock(nextSelectionBlock);

        // definido que o validator2 propôs blocos dentro da janela prevista
        uint256 lastBlockProposedByValidator2 = nextSelectionBlock - 2;
        assertLt(nextSelectionBlock - lastBlockProposedByValidator2, initialBlocksWithoutProposeThreshold);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector).with_key(
            validator2.addr
        ).checked_write(lastBlockProposedByValidator2);
        assertEq(validatorSelection.lastBlockProposedBy(validator2.addr), lastBlockProposedByValidator2);

        // definido que o validator3 propôs blocos dentro da janela prevista
        uint256 lastBlockProposedByValidator3 = nextSelectionBlock - 3;
        assertLt(nextSelectionBlock - lastBlockProposedByValidator3, initialBlocksWithoutProposeThreshold);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector).with_key(
            validator3.addr
        ).checked_write(lastBlockProposedByValidator3);
        assertEq(validatorSelection.lastBlockProposedBy(validator3.addr), lastBlockProposedByValidator3);

        // definido que o validator4 propôs blocos dentro da janela prevista
        uint256 lastBlockProposedByValidator4 = nextSelectionBlock - 4;
        assertLt(nextSelectionBlock - lastBlockProposedByValidator4, initialBlocksWithoutProposeThreshold);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector).with_key(
            validator4.addr
        ).checked_write(lastBlockProposedByValidator4);
        assertEq(validatorSelection.lastBlockProposedBy(validator4.addr), lastBlockProposedByValidator4);

        // definido que o validator5 propôs blocos dentro da janela prevista
        uint256 lastBlockProposedByValidator5 = nextSelectionBlock - 5;
        assertLt(nextSelectionBlock - lastBlockProposedByValidator5, initialBlocksWithoutProposeThreshold);
        stdstore.target(address(validatorSelection)).sig(validatorSelection.lastBlockProposedBy.selector).with_key(
            validator5.addr
        ).checked_write(lastBlockProposedByValidator5);
        assertEq(validatorSelection.lastBlockProposedBy(validator5.addr), lastBlockProposedByValidator5);

        // garante que o validator1 não propôs blocos
        assertEq(validatorSelection.lastBlockProposedBy(validator1.addr), 0);

        // esperamos que o validator1 seja removido
        address[] memory expectedRemovedValidators = new address[](1);
        expectedRemovedValidators[0] = validator1.addr;

        // vamos até o bloco que vai ocorrer a seleção
        vm.roll(nextSelectionBlock);

        // fazemos o monitoramento
        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit MonitorExecuted();
        vm.expectEmit(true, true, true, true);
        emit SelectionExecuted();
        // aqui, o array do evento emitido deve ser o array com a lista dos validadores que esperamos
        // que seja removido, no caso uma lista com apenas o validator1
        vm.expectEmit(true, true, true, true);
        emit ValidatorsRemoved(expectedRemovedValidators);
        validatorSelection.monitorsValidators();

        // agora devemos ter 4 operacionais ao invés de 5
        assertEq(validatorSelection.getActiveValidators().length, 4);

        // garantimos que foi o validator1 que foi removido
        address[] memory activeValidators = validatorSelection.getActiveValidators();
        uint256 activeValidatorsLength = activeValidators.length;
        for (uint256 i; i < activeValidatorsLength; i++) {
            assertNotEq(activeValidators[i], validator1.addr);
        }

        // espera-se também que o bloco da próxima seleção seja atualizado
        uint256 expectedNextSelectionBlock = nextSelectionBlock + initialBlocksBetweenSelection;
        assertEq(validatorSelection.nextSelectionBlock(), expectedNextSelectionBlock);
    }

    function test_setBlocksBetweenSelection() public {
        assertEq(validatorSelection.blocksBetweenSelection(), initialBlocksBetweenSelection);
        uint256 updateBlocksBetweenSelection = 10;
        vm.prank(address(governanceMock));
        validatorSelection.setBlocksBetweenSelection(updateBlocksBetweenSelection);
        assertEq(validatorSelection.blocksBetweenSelection(), updateBlocksBetweenSelection);
    }

    function test_setBlocksBetweenSelection_RevertsIfNotGovernance() public {
        Vm.Wallet memory notGovernance = vm.createWallet(1234);
        uint256 updateBlocksBetweenSelection = 10;
        vm.prank(notGovernance.addr);
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance.addr);
        vm.expectRevert(expectedError, proxyContractAddress);
        validatorSelection.setBlocksBetweenSelection(updateBlocksBetweenSelection);
    }

    function test_setBlocksWithoutProposeThreshold() public {
        assertEq(validatorSelection.blocksWithoutProposeThreshold(), initialBlocksWithoutProposeThreshold);
        uint256 updateBlocksWithoutProposeThreshold = 100;
        vm.prank(address(governanceMock));
        validatorSelection.setBlocksWithoutProposeThreshold(updateBlocksWithoutProposeThreshold);
        assertEq(validatorSelection.blocksWithoutProposeThreshold(), updateBlocksWithoutProposeThreshold);
    }

    function test_setBlocksWithoutProposeThreshold_RevertsIfNotGovernance() public {
        Vm.Wallet memory notGovernance = vm.createWallet(1234);
        uint256 updateBlocksWithoutProposeThreshold = 100;
        vm.prank(notGovernance.addr);
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance.addr);
        vm.expectRevert(expectedError, proxyContractAddress);
        validatorSelection.setBlocksWithoutProposeThreshold(updateBlocksWithoutProposeThreshold);
    }

    function test_setNextSelectionBlock() public {
        assertEq(validatorSelection.nextSelectionBlock(), initialNextSelectionBlock);
        uint256 updateNextSelectionBlock = 20;
        vm.prank(address(governanceMock));
        validatorSelection.setNextSelectionBlock(updateNextSelectionBlock);
        assertEq(validatorSelection.nextSelectionBlock(), updateNextSelectionBlock);
    }

    function test_setNextSelectionBlock_RevertsIfNotGovernance() public {
        Vm.Wallet memory notGovernance = vm.createWallet(1234);
        uint256 updateNextSelectionBlock = 20;
        vm.prank(notGovernance.addr);
        bytes memory expectedError = abi.encodeWithSelector(UnauthorizedAccess.selector, notGovernance.addr);
        vm.expectRevert(expectedError, proxyContractAddress);
        validatorSelection.setNextSelectionBlock(updateNextSelectionBlock);
    }

    function _getEnodeHighLow(Vm.Wallet memory _wallet) public pure returns (uint256, uint256) {
        uint256 enodeHigh = _wallet.publicKeyX;
        uint256 enodeLow = _wallet.publicKeyX;
        return (enodeHigh, enodeLow);
    }
}
