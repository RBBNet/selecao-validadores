// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {Script, console2} from "@forge-std/Script.sol";
import {stdJson} from "@forge-std/StdJson.sol";
import {ValidatorSelectionIngress} from "src/ValidatorSelectionIngress.sol";

contract DeployIngress is Script {
    using stdJson for string;

    function run() public {
        string memory json = vm.readFile(string.concat(vm.projectRoot(), "/script/data/config.json"));

        address adminProxy = json.readAddress(".contracts.adminProxy");
        address validatorSelection = json.readAddress(".contracts.validatorSelection");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.broadcast(privateKey);
        ValidatorSelectionIngress ingress = new ValidatorSelectionIngress(adminProxy, validatorSelection);

        console2.log("ValidatorSelectionIngress deployed at:", address(ingress));
        console2.log("Use este endereco em validatorcontractaddress na transicao QBFT do genesis.");
    }
}
