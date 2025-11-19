// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {INodeRulesProxy} from "src/interfaces/INodeRulesProxy.sol";

bytes32 constant CONNECTION_ALLOWED = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
bytes32 constant CONNECTION_DENIED = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

interface INodeRulesV2 is INodeRulesProxy {
    enum NodeType {
        Boot,
        Validator,
        Writer,
        WriterPartner,
        ObserverBoot,
        Observer,
        Other
    }

    struct NodeData {
        bytes32 enodeHigh;
        bytes32 enodeLow;
        NodeType nodeType;
        string name;
        uint256 orgId;
        bool active;
    }

    event NodeAdded(
        bytes32 indexed enodeHigh, bytes32 indexed enodeLow, uint256 indexed orgId, NodeType nodeType, string name
    );
    event NodeDeleted(bytes32 indexed enodeHigh, bytes32 indexed enodeLow, uint256 indexed orgId);
    event NodeUpdated(
        bytes32 indexed enodeHigh, bytes32 indexed enodeLow, uint256 indexed orgId, NodeType nodeType, string name
    );
    event NodeStatusUpdated(bytes32 indexed enodeHigh, bytes32 indexed enodeLow, uint256 indexed orgId, bool active);

    error InvalidArgument(string message);
    error InactiveAccount(address account, string message);
    error InvalidOrganization(uint256 orgId);
    error NotLocalNode(bytes32 enodeHigh, bytes32 enodeLow);
    error DuplicateNode(bytes32 enodeHigh, bytes32 enodeLow);
    error NodeNotFound(bytes32 enodeHigh, bytes32 enodeLow);
    error InvalidState(string message);
    error InactiveNode(bytes32 enodeHigh, bytes32 enodeLow);

    // Funções disponíveis apenas para administradores (globais e locais)
    function addLocalNode(bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string memory name) external;
    function deleteLocalNode(bytes32 enodeHigh, bytes32 enodeLow) external;
    function updateLocalNode(bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string memory name) external;
    function updateLocalNodeStatus(bytes32 enodeHigh, bytes32 enodeLow, bool active) external;

    // Funções disponíveis apenas para a governança
    function addNode(bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string memory name, uint256 orgId)
        external;
    function deleteNode(bytes32 enodeHigh, bytes32 enodeLow) external;

    // Funções disponíveis publicamente
    function isNodeActive(bytes32 enodeHigh, bytes32 enodeLow) external view returns (bool);
    function getNode(bytes32 enodeHigh, bytes32 enodeLow) external view returns (NodeData memory);
    function getNumberOfNodes() external view returns (uint256);
    function getNumberOfNodesByOrg(uint256 orgId) external view returns (uint256);
    function getNodes(uint256 pageNumber, uint256 pageSize) external view returns (NodeData[] memory);
    function getNodesByOrg(uint256 orgId, uint256 pageNumber, uint256 pageSize)
        external
        view
        returns (NodeData[] memory);

    function allowedNodes(uint256 nodeKey)
        external
        view
        returns (bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string memory name, uint256 orgId, bool active);
}
