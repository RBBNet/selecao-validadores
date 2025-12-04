// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.28;

import "./NodeRulesV2.sol";
import "./Governable.sol";
import "./AccountRulesV2.sol";
import "./Organization.sol";
import "./Pagination.sol";

contract NodeRulesV2Impl is NodeRulesV2, Governable {

    using EnumerableSet for EnumerableSet.UintSet;

    AccountRulesV2 public immutable accountsContract;
    Organization public immutable organizationsContract;
    mapping (uint => NodeData) public allowedNodes;
    EnumerableSet.UintSet private _nodesKeys;
    mapping (uint => EnumerableSet.UintSet) _nodesKeysByOrg;

    constructor(Organization orgs, AccountRulesV2 accs, AdminProxy adminProxy) Governable(adminProxy) {
        if(address(orgs) == address(0)) {
            revert InvalidArgument("Invalid address for Organization management smart contract");
        }
        if(address(accs) == address(0)) {
            revert InvalidArgument("Invalid address for Account management smart contract");
        }
        organizationsContract = orgs;
        accountsContract = accs;
    }
    
    modifier onlyActiveAdmin() {
        if(!accountsContract.hasRole(GLOBAL_ADMIN_ROLE, msg.sender) && !accountsContract.hasRole(LOCAL_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedAccess(msg.sender);
        }
        if(!accountsContract.isAccountActive(msg.sender)) {
            revert InactiveAccount(msg.sender, "The account or the respective organization is not active");
        }
        _;
    }

    modifier validName(string calldata name) {
        if(bytes(name).length == 0) {
            revert InvalidArgument("Node name cannot be empty.");
        }
        _;
    }

    function addLocalNode(bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string calldata name) public onlyActiveAdmin {
        AccountRulesV2.AccountData memory acc = accountsContract.getAccount(msg.sender);
        _addNode(enodeHigh, enodeLow, nodeType, name, acc.orgId);
    }

    function addNode(bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string calldata name, uint orgId) public onlyGovernance {
        if(!organizationsContract.isOrganizationActive(orgId)) {
            revert InvalidOrganization(orgId);
        }
        _addNode(enodeHigh, enodeLow, nodeType, name, orgId);
    }

    function _addNode(bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string calldata name, uint orgId) private validName(name) {
        uint256 key = _calculateKey(enodeHigh, enodeLow);
        _revertIfDuplicateNode(enodeHigh, enodeLow, key);
        allowedNodes[key] = NodeData(enodeHigh, enodeLow, nodeType, name, orgId, true);
        assert(_nodesKeys.add(key));
        assert(_nodesKeysByOrg[orgId].add(key));
        emit NodeAdded(enodeHigh, enodeLow, orgId, nodeType, name);
    }

    function deleteNode(bytes32 enodeHigh, bytes32 enodeLow) public onlyGovernance {
        uint256 key = _calculateKey(enodeHigh, enodeLow);
        _revertIfNodeNotFound(enodeHigh, enodeLow, key);
        _deleteNode(enodeHigh, enodeLow, key, allowedNodes[key].orgId);
    }

    function deleteLocalNode(bytes32 enodeHigh, bytes32 enodeLow) public onlyActiveAdmin {
        uint256 key = _calculateKey(enodeHigh, enodeLow);
        _revertIfNodeNotFound(enodeHigh, enodeLow, key);
        _revertIfNotSameOrganization(enodeHigh, enodeLow, key);
        _deleteNode(enodeHigh, enodeLow, key, allowedNodes[key].orgId);
    }
    
    function _deleteNode(bytes32 enodeHigh, bytes32 enodeLow, uint nodeKey, uint orgId) private {
        delete allowedNodes[nodeKey];
        assert(_nodesKeys.remove(nodeKey));
        assert(_nodesKeysByOrg[orgId].remove(nodeKey));
        emit NodeDeleted(enodeHigh, enodeLow, orgId);
    }

    function updateLocalNode(bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string calldata name) public onlyActiveAdmin validName(name) {
        uint256 key = _calculateKey(enodeHigh, enodeLow);
        _revertIfNodeNotFound(enodeHigh, enodeLow, key);
        _revertIfNotSameOrganization(enodeHigh, enodeLow, key);
        allowedNodes[key].nodeType = nodeType;
        allowedNodes[key].name = name;
        emit NodeUpdated(enodeHigh, enodeLow, allowedNodes[key].orgId, nodeType, name);
    }

    function updateLocalNodeStatus(bytes32 enodeHigh, bytes32 enodeLow, bool active) public onlyActiveAdmin {
        uint256 key = _calculateKey(enodeHigh, enodeLow);
        _revertIfNodeNotFound(enodeHigh, enodeLow, key);
        _revertIfNotSameOrganization(enodeHigh, enodeLow, key);
        allowedNodes[key].active = active;
        emit NodeStatusUpdated(enodeHigh, enodeLow, allowedNodes[key].orgId, active);
    }

    function isNodeActive(bytes32 enodeHigh, bytes32 enodeLow) public view returns (bool){
        uint256 key = _calculateKey(enodeHigh, enodeLow);
        NodeData storage node = allowedNodes[key];
        if(organizationsContract.isOrganizationActive(node.orgId) && node.active) {
            return true;
        }
        return false;
    }

    function getNode(bytes32 enodeHigh, bytes32 enodeLow) public view returns (NodeData memory){
        uint256 key = _calculateKey(enodeHigh, enodeLow);
        _revertIfNodeNotFound(enodeHigh, enodeLow, key);
        return allowedNodes[key];
    }

    function getNumberOfNodes() public view returns (uint) {
        return _nodesKeys.length();
    }

    function getNumberOfNodesByOrg(uint orgId) public view returns (uint) {
        return _nodesKeysByOrg[orgId].length();
    }

    function getNodes(uint pageNumber, uint pageSize) public view returns (NodeData[] memory) {
        return _getNodes(_nodesKeys, pageNumber, pageSize);
    }

    function getNodesByOrg(uint orgId, uint pageNumber, uint pageSize) public view returns (NodeData[] memory) {
        return _getNodes(_nodesKeysByOrg[orgId], pageNumber, pageSize);
    }

    function _getNodes(EnumerableSet.UintSet storage nodeKeySet, uint pageNumber, uint pageSize) private view returns (NodeData[] memory) {
        uint[] memory page = Pagination.getUintPage(nodeKeySet, pageNumber, pageSize);
        NodeData[] memory nodes = new NodeData[](page.length);
        for(uint i = 0; i < nodes.length; ++i) {
            nodes[i] = allowedNodes[page[i]];
        }
        return nodes;
    }

    function connectionAllowed(
        bytes32 sourceEnodeHigh,
        bytes32 sourceEnodeLow,
        bytes16,
        uint16,
        bytes32 destinationEnodeHigh,
        bytes32 destinationEnodeLow,
        bytes16,
        uint16
    ) public view returns (bytes32) {
        if(isNodeActive(sourceEnodeHigh, sourceEnodeLow) && isNodeActive(destinationEnodeHigh, destinationEnodeLow)) {
            return CONNECTION_ALLOWED;
        }
        
        return CONNECTION_DENIED;
    }

    function _revertIfDuplicateNode(bytes32 enodeHigh, bytes32 enodeLow, uint nodeKey) private view {
        if(_nodeExists(nodeKey)) {
            revert DuplicateNode(enodeHigh, enodeLow);
        }
    }

    function _revertIfNodeNotFound(bytes32 enodeHigh, bytes32 enodeLow, uint nodeKey) private view {
        if(!_nodeExists(nodeKey)) {
            revert NodeNotFound(enodeHigh, enodeLow);
        }
    }

    function _revertIfNotSameOrganization(bytes32 enodeHigh, bytes32 enodeLow, uint nodeKey) private view {
        AccountRulesV2.AccountData memory acc = accountsContract.getAccount(msg.sender);
        if(acc.orgId != allowedNodes[nodeKey].orgId) {
            revert NotLocalNode(enodeHigh, enodeLow);
        }
    }

    function _nodeExists(uint nodeKey) private view returns(bool) {
        return allowedNodes[nodeKey].orgId != 0;
    }

    function _calculateKey(bytes32 enodeHigh, bytes32 enodeLow) private pure returns(uint) {
        return uint(keccak256(abi.encodePacked(enodeHigh, enodeLow)));
    }

}
