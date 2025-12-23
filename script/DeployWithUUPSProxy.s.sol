pragma solidity ^0.8.13;

import {Script, console2} from "@forge-std/Script.sol";
import {stdJson} from "@forge-std/StdJson.sol";
import {Upgrades} from "@forge-upgrades/Upgrades.sol";
import {IAdminProxy} from "src/interfaces/IAdminProxy.sol";
import {IAccountRulesV2} from "src/interfaces/IAccountRulesV2.sol";
import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";
import {ValidatorSelection} from "src/ValidatorSelection.sol";

contract DeployWithUUPSProxy is Script {
    using stdJson for string;

    IAdminProxy public adminsProxy;
    INodeRulesV2 public nodesContract;
    IAccountRulesV2 public accountsContract;
    ValidatorSelection public validatorSelection;

    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployerAddress = vm.addr(privateKey);

    function run() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/data/config.json");
        string memory json = vm.readFile(path);

        adminsProxy = IAdminProxy(json.readAddress(".contracts.adminsProxy"));
        accountsContract = IAccountRulesV2(json.readAddress(".contracts.accountRules"));
        nodesContract = INodeRulesV2(json.readAddress(".contracts.nodeRules"));

        uint256 initialBlocksBetweenSelection = json.readUint(".initialBlocksBetweenSelection");
        uint256 initialBlocksWithoutProposeThreshold = json.readUint(".initialBlocksWithoutProposeThreshold");
        uint256 initialNextSelectionBlock = json.readUint(".initialNextSelectionBlock");
        address[] memory initialElegibleValidators = json.readAddressArray(".initialElegibleValidators");

        vm.broadcast(privateKey);
        address proxy = Upgrades.deployUUPSProxy(
            "ValidatorSelection.sol",
            abi.encodeCall(
                ValidatorSelection.initialize,
                (
                    adminsProxy,
                    accountsContract,
                    nodesContract,
                    initialElegibleValidators,
                    initialBlocksBetweenSelection,
                    initialBlocksWithoutProposeThreshold,
                    initialNextSelectionBlock
                )
            )
        );
    }
}
