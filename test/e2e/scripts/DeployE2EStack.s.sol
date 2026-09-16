// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import {Script, console2} from "@forge-std/Script.sol";
import {Admin} from "permissioning/Admin.sol";
import {AdminProxy} from "permissioning/AdminProxy.sol";
import {Organization} from "permissioning/Organization.sol";
import {OrganizationImpl} from "permissioning/OrganizationImpl.sol";
import {AccountRulesV2} from "permissioning/AccountRulesV2.sol";
import {AccountRulesV2Impl} from "permissioning/AccountRulesV2Impl.sol";
import {NodeRulesV2Impl} from "permissioning/NodeRulesV2Impl.sol";
import {IAccountRulesV2} from "src/interfaces/IAccountRulesV2.sol";
import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";
import {ValidatorSelection} from "src/ValidatorSelection.sol";
import {ValidatorSelectionIngress} from "src/ValidatorSelectionIngress.sol";

/// Sobe a pilha completa de permissionamento real (sem dublês) e, sobre ela,
/// ValidatorSelection + ValidatorSelectionIngress, na ordem exigida pelo README.
/// Lê do ambiente: PRIVATE_KEY, E2E_VALIDATORS, E2E_BLOCKS_BETWEEN_SELECTION,
/// E2E_BLOCKS_WITHOUT_PROPOSE_THRESHOLD, E2E_SELECTION_OFFSET, E2E_ORG2_ADMIN.
contract DeployE2EStack is Script {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address[] memory validators = vm.envAddress("E2E_VALIDATORS", ",");
        uint256 blocksBetweenSelection = vm.envUint("E2E_BLOCKS_BETWEEN_SELECTION");
        uint256 blocksWithoutProposeThreshold = vm.envUint("E2E_BLOCKS_WITHOUT_PROPOSE_THRESHOLD");
        uint256 selectionOffset = vm.envUint("E2E_SELECTION_OFFSET");

        vm.startBroadcast(privateKey);

        Admin admin = new Admin();

        Organization.OrganizationData[] memory orgs = new Organization.OrganizationData[](2);
        orgs[0] =
            Organization.OrganizationData(0, "00000000000191", "Org A", Organization.OrganizationType.Patron, true);
        orgs[1] =
            Organization.OrganizationData(0, "00000000000272", "Org B", Organization.OrganizationType.Patron, true);
        OrganizationImpl organizations = new OrganizationImpl(orgs, AdminProxy(address(admin)));

        address[] memory globalAdmins = new address[](2);
        globalAdmins[0] = vm.addr(privateKey);
        globalAdmins[1] = vm.envAddress("E2E_ORG2_ADMIN");
        AccountRulesV2Impl accounts =
            new AccountRulesV2Impl(Organization(address(organizations)), globalAdmins, AdminProxy(address(admin)));

        NodeRulesV2Impl nodes = new NodeRulesV2Impl(
            Organization(address(organizations)), AccountRulesV2(address(accounts)), AdminProxy(address(admin))
        );

        ValidatorSelection selection = new ValidatorSelection(
            AdminProxy(address(admin)),
            IAccountRulesV2(address(accounts)),
            INodeRulesV2(address(nodes)),
            validators,
            blocksBetweenSelection,
            blocksWithoutProposeThreshold,
            block.number + selectionOffset
        );

        ValidatorSelectionIngress ingress = new ValidatorSelectionIngress(address(admin), address(selection));

        vm.stopBroadcast();

        console2.log("ADMIN=%s", address(admin));
        console2.log("ORGANIZATIONS=%s", address(organizations));
        console2.log("ACCOUNTS=%s", address(accounts));
        console2.log("NODES=%s", address(nodes));
        console2.log("SELECTION=%s", address(selection));
        console2.log("INGRESS=%s", address(ingress));
    }
}
