// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";

contract NodeRulesV2Mock is INodeRulesV2 {
    function allowedNodes(uint256 nodeKey)
        external
        view
        returns (bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string memory name, uint256 orgId, bool active)
    {
        return (bytes32("1"), bytes32("2"), NodeType.Validator, "mock", 1, true);
    }

    function connectionAllowed(
        bytes32 sourceEnodeHigh,
        bytes32 sourceEnodeLow,
        bytes16 sourceEnodeIp,
        uint16 sourceEnodePort,
        bytes32 destinationEnodeHigh,
        bytes32 destinationEnodeLow,
        bytes16 destinationEnodeIp,
        uint16 destinationEnodePort
    ) external view returns (bytes32) {
        revert("NotSupported: LocalAccount management");
    }

    function addLocalNode(bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string memory name) external {
        revert("NotSupported: LocalAccount management");
    }

    function deleteLocalNode(bytes32 enodeHigh, bytes32 enodeLow) external {
        revert("NotSupported: LocalAccount management");
    }

    function updateLocalNode(bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string memory name) external {
        revert("NotSupported: LocalAccount management");
    }

    function updateLocalNodeStatus(bytes32 enodeHigh, bytes32 enodeLow, bool active) external {
        revert("NotSupported: LocalAccount management");
    }

    function addNode(bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string memory name, uint256 orgId)
        external
    {
        revert("NotSupported: LocalAccount management");
    }

    function deleteNode(bytes32 enodeHigh, bytes32 enodeLow) external {
        revert("NotSupported: LocalAccount management");
    }

    function isNodeActive(bytes32 enodeHigh, bytes32 enodeLow) external view returns (bool) {
        revert("NotSupported: LocalAccount management");
    }

    function getNode(bytes32 enodeHigh, bytes32 enodeLow) external view returns (NodeData memory) {
        revert("NotSupported: LocalAccount management");
    }

    function getNumberOfNodes() external view returns (uint256) {
        revert("NotSupported: LocalAccount management");
    }

    function getNumberOfNodesByOrg(uint256 orgId) external view returns (uint256) {
        revert("NotSupported: LocalAccount management");
    }

    function getNodes(uint256 pageNumber, uint256 pageSize) external view returns (NodeData[] memory) {
        revert("NotSupported: LocalAccount management");
    }

    function getNodesByOrg(uint256 orgId, uint256 pageNumber, uint256 pageSize)
        external
        view
        returns (NodeData[] memory)
    {
        revert("NotSupported: LocalAccount management");
    }
}
