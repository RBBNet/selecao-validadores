// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";

contract NodeRulesV2Mock is INodeRulesV2 {
    function allowedNodes(uint256)
        external
        pure
        returns (bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string memory name, uint256 orgId, bool active)
    {
        return (bytes32("1"), bytes32("2"), NodeType.Validator, "mock", 1, true);
    }

    function connectionAllowed(bytes32, bytes32, bytes16, uint16, bytes32, bytes32, bytes16, uint16)
        external
        pure
        returns (bytes32)
    {
        revert("NotSupported: LocalAccount management");
    }

    function addLocalNode(bytes32, bytes32, NodeType, string memory) external pure {
        revert("NotSupported: LocalAccount management");
    }

    function deleteLocalNode(bytes32, bytes32) external pure {
        revert("NotSupported: LocalAccount management");
    }

    function updateLocalNode(bytes32, bytes32, NodeType, string memory) external pure {
        revert("NotSupported: LocalAccount management");
    }

    function updateLocalNodeStatus(bytes32, bytes32, bool) external pure {
        revert("NotSupported: LocalAccount management");
    }

    function addNode(bytes32, bytes32, NodeType, string memory, uint256) external pure {
        revert("NotSupported: LocalAccount management");
    }

    function deleteNode(bytes32, bytes32) external pure {
        revert("NotSupported: LocalAccount management");
    }

    function isNodeActive(bytes32, bytes32) external pure returns (bool) {
        revert("NotSupported: LocalAccount management");
    }

    function getNode(bytes32, bytes32) external pure returns (NodeData memory) {
        revert("NotSupported: LocalAccount management");
    }

    function getNumberOfNodes() external pure returns (uint256) {
        revert("NotSupported: LocalAccount management");
    }

    function getNumberOfNodesByOrg(uint256) external pure returns (uint256) {
        revert("NotSupported: LocalAccount management");
    }

    function getNodes(uint256, uint256) external pure returns (NodeData[] memory) {
        revert("NotSupported: LocalAccount management");
    }

    function getNodesByOrg(uint256, uint256, uint256) external pure returns (NodeData[] memory) {
        revert("NotSupported: LocalAccount management");
    }
}
