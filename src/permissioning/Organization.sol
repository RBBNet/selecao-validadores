// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.28;

interface Organization {

    enum OrganizationType {
        Partner,
        Associate,
        Patron
    }

    struct OrganizationData {
        uint id;
        string cnpj;
        string name;
        OrganizationType orgType;
        bool canVote;
    }

    event OrganizationAdded(uint indexed orgId, string cnpj, string name, OrganizationType orgType, bool canVote);
    event OrganizationUpdated(uint indexed orgId, string cnpj, string name, OrganizationType orgType, bool canVote);
    event OrganizationDeleted(uint indexed orgId);

    error OrganizationNotFound(uint orgId);
    error InvalidArgument(string message);
    error IllegalState(string message);

    // Funções disponíveis apenas para a governança
    function addOrganization(string calldata cnpj, string calldata name, OrganizationType orgType, bool canVote) external returns (uint);
    function updateOrganization(uint orgId, string calldata cnpj, string calldata name, OrganizationType orgType, bool canVote) external;
    function deleteOrganization(uint orgId) external;

    // Funções disponíveis publicamente
    function isOrganizationActive(uint orgId) external view returns (bool);
    function getOrganization(uint orgId) external view returns (OrganizationData memory);
    function getOrganizations() external view returns (OrganizationData[] memory);

}