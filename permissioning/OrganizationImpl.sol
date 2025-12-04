// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.28;

import "./Organization.sol";
import "./Governable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract OrganizationImpl is Organization, Governable {

    using EnumerableSet for EnumerableSet.UintSet;

    uint public idSeed = 0;
    mapping (uint => OrganizationData) public organizations;
    EnumerableSet.UintSet private _organizationIds;

    modifier existentOrganization(uint orgId) {
        if(organizations[orgId].id == 0) {
            revert OrganizationNotFound(orgId);
        }
        _;
    }

    modifier onlyIfMinimumActiveOrganizations() {
        if(_organizationIds.length() < 3) {
            revert IllegalState("At least 2 organizations must be active");
        }
        _;
    }

    modifier validCnpj(string memory cnpj) {
        if(bytes(cnpj).length == 0) {
            revert InvalidArgument("Organization CNPJ cannot be empty.");
        }
        _;
    }

    modifier validName(string memory name) {
        if(bytes(name).length == 0) {
            revert InvalidArgument("Organization name cannot be empty.");
        }
        _;
    }

    modifier validPermissionToVote(OrganizationType orgType, bool canVote) {
        if(canVote && orgType == OrganizationType.Partner) {
            revert InvalidArgument("Partner organizations cannot vote");
        }
        _;
    }

    constructor(OrganizationData[] memory orgs, AdminProxy adminsProxy) Governable(adminsProxy) {
        require(orgs.length >= 2, "At least 2 organizations must exist");
        for(uint i = 0; i < orgs.length; ++i) {
            _addOrganization(orgs[i].cnpj, orgs[i].name, orgs[i].orgType, orgs[i].canVote);
        }
    }

    function addOrganization(string calldata cnpj, string calldata name, OrganizationType orgType, bool canVote) public onlyGovernance returns (uint) {
        return _addOrganization(cnpj, name, orgType, canVote);
    }

    function _addOrganization(string memory cnpj, string memory name, OrganizationType orgType, bool canVote) private
        validCnpj(cnpj) validName(name) validPermissionToVote(orgType, canVote) returns (uint) {
        uint newId = ++idSeed;
        OrganizationData memory newOrg = OrganizationData(newId, cnpj, name, orgType, canVote);
        organizations[newId] = newOrg;
        assert(_organizationIds.add(newId));
        emit OrganizationAdded(newId, cnpj, name, orgType, canVote);
        return newId;
    }

    function updateOrganization(uint orgId, string calldata cnpj, string calldata name, OrganizationType orgType, bool canVote) public
        onlyGovernance existentOrganization(orgId) validCnpj(cnpj) validName(name) validPermissionToVote(orgType, canVote) {
        OrganizationData storage org = organizations[orgId];
        org.cnpj = cnpj;
        org.name = name;
        org.orgType = orgType;
        org.canVote = canVote;
        emit OrganizationUpdated(orgId, cnpj, name, orgType, canVote);
    }

    function deleteOrganization(uint orgId) public onlyGovernance existentOrganization(orgId) onlyIfMinimumActiveOrganizations {
        delete organizations[orgId];
        assert(_organizationIds.remove(orgId));
        emit OrganizationDeleted(orgId);
    }

    function isOrganizationActive(uint orgId) public view returns (bool) {
        return organizations[orgId].id > 0;
    }

    function getOrganization(uint orgId) public view existentOrganization(orgId) returns (OrganizationData memory) {
        return organizations[orgId];
    }

    function getOrganizations() public view returns (OrganizationData[] memory) {
        OrganizationData[] memory orgs = new OrganizationData[](_organizationIds.length());
        for(uint i = 0; i < _organizationIds.length(); ++i) {
            orgs[i] = organizations[_organizationIds.at(i)];
        }
        return orgs;
    }

    function organizationIds() public view returns (uint[] memory) {
        return _organizationIds.values();
    }

}