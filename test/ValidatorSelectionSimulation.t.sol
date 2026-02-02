// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Upgrades} from "lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";
import "../src/ValidatorSelection.sol";
import {AccountRulesV2Mock} from "test/mocks/AccountRulesV2Mock.sol";
import {NodeRulesV2Mock} from "test/mocks/NodeRulesV2Mock.sol";

contract MockAdminProxy is IAdminProxy {
    function getAdmin() external view returns (address) {
        return msg.sender;
    }

    function isAuthorized(address) external view returns (bool) {
        return true;
    }
}

contract ValidatorSelectionSimulationTest is Test {
    ValidatorSelection public selection;
    address proxyContractAddress;
    address[] public validators;
    uint256 public constant TOTAL_VALIDATORS = 10;

    function setUp() public {
        for (uint i = 0; i < TOTAL_VALIDATORS; i++) {
            address val = address(uint160(0x1000 + i));
            require(val != address(0), "Validador zero");
            for (uint j = 0; j < i; j++) {
                require(validators[j] != val, "Validador duplicado");
            }
            validators.push(val);
        }

        MockAdminProxy adminProxy = new MockAdminProxy();
        AccountRulesV2Mock accountRulesMock = new AccountRulesV2Mock();
        NodeRulesV2Mock nodeRulesMock = new NodeRulesV2Mock();

        uint256 blocksBetweenSelection = 10; 
        uint256 blocksWithoutProposeThreshold = 20;
        uint256 nextSelectionBlock = 100; 

        proxyContractAddress = Upgrades.deployUUPSProxy(
            "ValidatorSelection.sol",
            abi.encodeCall(
                ValidatorSelection.initialize,
                (
                    adminProxy,
                    accountRulesMock,
                    nodeRulesMock,
                    validators,
                    blocksBetweenSelection,
                    blocksWithoutProposeThreshold,
                    nextSelectionBlock
                )
            )
        );
        selection = ValidatorSelection(proxyContractAddress);
    }

    function testSimulacaoDeRedeReal() public {
        console.log("\n=== INICIO DA SIMULACAO ===");

        vm.startPrank(address(0));
        for (uint i = 0; i < TOTAL_VALIDATORS; i++) {
            selection.addOperationalValidator(validators[i]);
        }
        vm.stopPrank();

        console.log("[FASE 1] Rede saudavel: todos validadores ativos");
        for (uint i = 0; i < 100; i++) {
            address mineradorDaVez = validators[i % TOTAL_VALIDATORS];
            vm.coinbase(mineradorDaVez);
            vm.roll(block.number + 1);
            selection.monitorsValidators();
        }
        uint256 ativos = selection.getOperationalValidatorsCount();
        console.log("Validadores ativos apos 100 blocos:", ativos);
        assertEq(ativos, 10, "Todos devem estar vivos");
        console.log("[OK] Fase saudavel: 10 validadores ativos");

        console.log("\n[FASE 2] Dois validadores desligam: 5 e 7");
        address validadorMorto1 = validators[5];
        address validadorMorto2 = validators[7];
        for (uint i = 0; i < 300; i++) {
            uint index = i % TOTAL_VALIDATORS;
            if (index == 5 || index == 7) continue;
            address mineradorDaVez = validators[index];
            vm.coinbase(mineradorDaVez);
            vm.roll(block.number + 1);
            selection.monitorsValidators();
        }
        uint256 ativos2 = selection.getOperationalValidatorsCount();
        bool estaVivo1 = selection.isOperationalValidator(validadorMorto1);
        bool estaVivo2 = selection.isOperationalValidator(validadorMorto2);
        console.log("Validadores ativos apos 300 blocos:", ativos2);
        console.log("Validador 5 ativo?", estaVivo1);
        console.log("Validador 7 ativo?", estaVivo2);
        assertEq(ativos2, 8, "Deveria ter removido 2 validadores");
        assertFalse(estaVivo1, "Validador 5 deveria ter sido removido");
        assertFalse(estaVivo2, "Validador 7 deveria ter sido removido");
        console.log("[OK] Fase acidente: 2 validadores removidos");
        console.log("\n[FASE 3] Remocao ate o minimo de validadores");

        for (uint i = 0; i < 1000; i++) {
            uint index = i % 4; 
            address mineradorDaVez = validators[index];
            vm.coinbase(mineradorDaVez);
            vm.roll(block.number + 1);
            selection.monitorsValidators();
        }
        uint256 ativos3 = selection.getOperationalValidatorsCount();
        console.log("Validadores ativos apos remocao em massa:", ativos3);
        assertEq(ativos3, 4, "Deveria restar apenas o minimo permitido");
        console.log(
            "[OK] Fase minimo: contrato respeita o minimo de validadores"
        );

        console.log("\n[FASE 4] Reentrada de validador removido");
        vm.startPrank(address(0));
        if (selection.isOperationalValidator(validators[5])) {
            selection.removeOperationalValidator(validators[5]);
        }
        if (selection.isEligibleValidator(validators[5])) {
            selection.removeEligibleValidator(validators[5]);
        }
        selection.addEligibleValidator(validators[5]);
        selection.addOperationalValidator(validators[5]);
        vm.stopPrank();

        uint256 ativos4 = selection.getOperationalValidatorsCount();
        bool voltou = selection.isOperationalValidator(validators[5]);
        console.log("Validadores ativos apos reentrada:", ativos4);
        console.log("Validador 5 voltou?", voltou);
        assertEq(ativos4, 5, "Deveria ter 5 validadores apos reentrada");
        assertTrue(voltou, "Validador 5 deveria ter voltado");
        console.log("[OK] Fase reentrada: validador removido pode voltar");

        console.log("\n=== FIM DA SIMULACAO ===\n");
    }
}
