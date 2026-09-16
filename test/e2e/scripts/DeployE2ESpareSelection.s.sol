// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import {Script, console2} from "@forge-std/Script.sol";
import {AdminProxy} from "permissioning/AdminProxy.sol";
import {IAccountRulesV2} from "src/interfaces/IAccountRulesV2.sol";
import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";
import {ValidatorSelection} from "src/ValidatorSelection.sol";

/// Segunda instância da lógica, reaproveitando a pilha de permissionamento já
/// implantada. Serve para exercitar a troca do contrato registrado no Ingress —
/// o único mecanismo de atualização do sistema — com a rede no ar.
/// O conjunto inicial é propositalmente menor que o da instância principal, para
/// que a resposta do Ingress mude de forma observável após a troca.
/// Lê do ambiente: PRIVATE_KEY, E2E_SPARE_VALIDATORS, E2E_ADMIN, E2E_ACCOUNTS,
/// E2E_NODES, E2E_BLOCKS_BETWEEN_SELECTION, E2E_BLOCKS_WITHOUT_PROPOSE_THRESHOLD,
/// E2E_SELECTION_OFFSET.
contract DeployE2ESpareSelection is Script {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address[] memory validators = vm.envAddress("E2E_SPARE_VALIDATORS", ",");

        vm.startBroadcast(privateKey);

        ValidatorSelection spare = new ValidatorSelection(
            AdminProxy(vm.envAddress("E2E_ADMIN")),
            IAccountRulesV2(vm.envAddress("E2E_ACCOUNTS")),
            INodeRulesV2(vm.envAddress("E2E_NODES")),
            validators,
            vm.envUint("E2E_BLOCKS_BETWEEN_SELECTION"),
            vm.envUint("E2E_BLOCKS_WITHOUT_PROPOSE_THRESHOLD"),
            block.number + vm.envUint("E2E_SELECTION_OFFSET")
        );

        vm.stopBroadcast();

        console2.log("SPARE_SELECTION=%s", address(spare));
    }
}
