// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import {Script, console2} from "@forge-std/Script.sol";
import {stdJson} from "@forge-std/StdJson.sol";
import {ValidatorSelectionIngress} from "src/ValidatorSelectionIngress.sol";

contract DeployIngress is Script {
    using stdJson for string;

    error ValidatorSelectionNotConfigured();
    error ValidatorSelectionHasNoCode(address addr);

    function run() public {
        string memory json = vm.readFile(string.concat(vm.projectRoot(), "/script/data/config.json"));

        address adminProxy = json.readAddress(".contracts.adminProxy");

        string memory rawValidatorSelection = json.readString(".contracts.validatorSelection");
        if (bytes(rawValidatorSelection).length == 0) revert ValidatorSelectionNotConfigured();

        address validatorSelection = vm.parseAddress(rawValidatorSelection);
        if (validatorSelection == address(0)) revert ValidatorSelectionNotConfigured();
        if (validatorSelection.code.length == 0) revert ValidatorSelectionHasNoCode(validatorSelection);

        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.broadcast(privateKey);
        ValidatorSelectionIngress ingress = new ValidatorSelectionIngress(adminProxy, validatorSelection);

        console2.log("ValidatorSelectionIngress deployed at:", address(ingress));
        console2.log("Use este endereco em validatorcontractaddress na transicao QBFT do genesis.");
    }
}
