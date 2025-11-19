pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {IAdminProxy} from "src/interfaces/IAdminProxy.sol";
import {IAccountRulesV2} from "src/interfaces/IAccountRulesV2.sol";
import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";
import {ValidatorSelection} from "src/ValidatorSelection.sol";

contract ValidatorSelectionDeploy is Script {
    IAdminProxy public adminsProxy;
    INodeRulesV2 public nodesContract;
    IAccountRulesV2 public accountsContract;
    ValidatorSelection public validatorSelection;

    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployerAddress = vm.addr(privateKey);

    function run() public {
        adminsProxy = IAdminProxy(vm.envAddress("ADMIN_CONTRACT"));
        accountsContract = IAccountRulesV2(vm.envAddress("ACCOUNT_RULES_CONTRACT"));
        nodesContract = INodeRulesV2(vm.envAddress("NODE_RULES_CONTRACT"));

        vm.broadcast(privateKey);
        validatorSelection = new ValidatorSelection(adminsProxy, accountsContract, nodesContract);
    }
}
