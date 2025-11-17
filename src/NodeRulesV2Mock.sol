// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.28;

contract NodeRulesV2Mock {
    enum NodeType {
        Boot,
        Validator,
        Writer,
        WriterPartner,
        ObserverBoot,
        Observer,
        Other
    }
    
    function allowedNodes(uint nodeKey) external view returns (bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string memory name, uint orgId, bool active){
        return (bytes32('1'), bytes32('2'), NodeType.Validator, "mock", 1, true);
    }
}
