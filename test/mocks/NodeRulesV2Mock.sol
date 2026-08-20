// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {INodeRulesV2} from "src/interfaces/INodeRulesV2.sol";

contract NodeRulesV2Mock is INodeRulesV2 {
    NodeType private _nodeType = NodeType.Validator;
    string private _name = "mock";
    uint256 private _orgId = 1;
    bool private _active = true;

    struct NodeOverride {
        bool exists;
        NodeType nodeType;
        string name;
        uint256 orgId;
        bool active;
    }
    mapping(uint256 => NodeOverride) private _overrides;

    function setNode(NodeType nodeType, string memory name, uint256 orgId, bool active) external {
        _nodeType = nodeType;
        _name = name;
        _orgId = orgId;
        _active = active;
    }

    function setNodeOverride(uint256 nodeKey, NodeType nodeType, string memory name, uint256 orgId, bool active)
        external
    {
        _overrides[nodeKey] = NodeOverride(true, nodeType, name, orgId, active);
    }

    function clearNodeOverride(uint256 nodeKey) external {
        delete _overrides[nodeKey];
    }

    function allowedNodes(uint256 nodeKey)
        external
        view
        returns (bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string memory name, uint256 orgId, bool active)
    {
        NodeOverride storage o = _overrides[nodeKey];
        if (o.exists) {
            return (bytes32(uint256(nodeKey)), bytes32(0), o.nodeType, o.name, o.orgId, o.active);
        }
        if (nodeKey == 0) {
            return (bytes32(0), bytes32(0), NodeType.Boot, "", 0, false);
        }
        return (bytes32("1"), bytes32("2"), _nodeType, _name, _orgId, _active);
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

    bool private _nodeActive = true;

    function setNodeActive(bool active) external {
        _nodeActive = active;
    }

    function isNodeActive(bytes32, bytes32) external view returns (bool) {
        return _nodeActive;
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
