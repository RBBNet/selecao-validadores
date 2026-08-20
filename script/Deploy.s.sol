// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {Script, console2} from "@forge-std/Script.sol";
import {stdJson} from "@forge-std/StdJson.sol";
import {AdminProxy} from "permissioning/AdminProxy.sol";
import {IAccountRulesV2} from "src/interfaces/IAccountRulesV2.sol";
import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";
import {ValidatorSelection} from "src/ValidatorSelection.sol";

contract Deploy is Script {
    using stdJson for string;

    function run() public {
        string memory json = vm.readFile(string.concat(vm.projectRoot(), "/script/data/config.json"));

        AdminProxy adminsProxy = AdminProxy(json.readAddress(".contracts.adminProxy"));
        IAccountRulesV2 accountsContract = IAccountRulesV2(json.readAddress(".contracts.accountRules"));
        INodeRulesV2 nodesContract = INodeRulesV2(json.readAddress(".contracts.nodeRules"));

        uint256 initialBlocksBetweenSelection = json.readUint(".initialBlocksBetweenSelection");
        uint256 initialBlocksWithoutProposeThreshold = json.readUint(".initialBlocksWithoutProposeThreshold");
        uint256 initialNextSelectionBlock = json.readUint(".initialNextSelectionBlock");
        address[] memory initialEligibleValidators = json.readAddressArray(".initialEligibleValidators");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.broadcast(privateKey);
        ValidatorSelection validatorSelection = new ValidatorSelection(
            adminsProxy,
            accountsContract,
            nodesContract,
            initialEligibleValidators,
            initialBlocksBetweenSelection,
            initialBlocksWithoutProposeThreshold,
            initialNextSelectionBlock
        );

        console2.log("ValidatorSelection deployed at:", address(validatorSelection));
    }
}
