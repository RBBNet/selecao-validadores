// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.28;

import "./AdminProxy.sol";
import "./Organization.sol";
import "./AccountRulesV2.sol";
import "./Pagination.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract Governance {

    enum ProposalStatus { Active, Canceled, Finished, Executed }
    enum ProposalResult { Undefined, Approved, Rejected }
    enum ProposalVote { NotVoted, Approval, Rejection }

    struct ProposalData {
        uint id;
        uint proponentOrgId;
        address[] targets;
        bytes[] calldatas;
        uint blocksDuration;
        string description;
        uint creationBlock;
        ProposalStatus status;
        ProposalResult result;
        uint[] organizations;
        ProposalVote[] votes;
        string cancelationReason;
    }

    event ProposalCreated(uint indexed proposalI, address[] targets, bytes[] calldatas, uint blocksDuration, string description);
    event OrganizationVoted(uint indexed proposalId, uint orgId, bool approve);
    event ProposalCanceled(uint indexed proposalId, string reason);
    event ProposalFinished(uint indexed proposalId);
    event ProposalApproved(uint indexed proposalId);
    event ProposalRejected(uint indexed proposalId);
    event ProposalExecuted(uint indexed proposalId);

    error UnauthorizedAccess(address account, string message);
    error IllegalState(string message);
    error InvalidArgument(string message);
    error ProposalNotFound(uint proposalId);

    uint public idSeed = 0;
    AdminProxy immutable public admins;
    Organization immutable public organizations;
    AccountRulesV2 immutable public accounts;
    ProposalData[] public proposals;

    modifier onlyActiveGlobalAdmin() {
        if(!accounts.hasRole(GLOBAL_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedAccess(msg.sender, "Sender is not a global admin");
        }
        if(!accounts.isAccountActive(msg.sender)) {
            revert UnauthorizedAccess(msg.sender, "Sender account is not active");
        }
        _;
    }

    modifier onlyActiveGlobalAdminOrGovernance() {
        if(!admins.isAuthorized(msg.sender) && !accounts.hasRole(GLOBAL_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedAccess(msg.sender, "Sender is not a global admin nor Governance");
        }
        if(!admins.isAuthorized(msg.sender) && !accounts.isAccountActive(msg.sender)) {
            revert UnauthorizedAccess(msg.sender, "Sender account is not active");
        }
        _;
    }

    modifier onlyParticipantOrganization(uint proposalId) {
        uint orgId = accounts.getAccount(msg.sender).orgId;
        ProposalData storage proposal = _getProposal(proposalId);
        uint orgNdx = _getOrganizationIndex(proposal, orgId);
        if(orgNdx >= proposal.organizations.length) {
            revert UnauthorizedAccess(msg.sender, "Sender's organization does not participate on the proposal");
        }
        _;
    }

    modifier existentProposal(uint proposalId) {
        if(proposalId == 0 || proposalId > proposals.length) {
            revert ProposalNotFound(proposalId);
        }
        _;
    }

    modifier onlyActiveProposal(uint proposalId) {
        if(_getProposal(proposalId).status != ProposalStatus.Active) {
            revert IllegalState("Proposal is not Active");
        }
        _;
    }

    modifier onlyActiveOrFinishedProposal(uint proposalId) {
        ProposalData storage proposal = _getProposal(proposalId);
        if(proposal.status != ProposalStatus.Active && proposal.status != ProposalStatus.Finished) {
            revert IllegalState("Proposal is not Active nor Finished");
        }
        _;
    }

    modifier onlyDefinedProposal(uint proposalId) {
        if(_getProposal(proposalId).result == ProposalResult.Undefined) {
            revert IllegalState("Proposal result is not defined");
        }
        _;
    }

    modifier onlyProponentOrganizationOrGovernance(uint proposalId) {
        if(!admins.isAuthorized(msg.sender) && _getProposal(proposalId).proponentOrgId != accounts.getAccount(msg.sender).orgId) {
            revert UnauthorizedAccess(msg.sender, "Sender is not from proponent organization nor Governance");
        }
        _;
    }

    modifier matchingCalls(uint targetsLength, uint calldatasLength) {
        if(targetsLength != calldatasLength) {
            revert InvalidArgument("Targets and calldatas arrays must have the same length");
        }
        _;
    }

    modifier validDuration(uint blocksDuration) {
        if(blocksDuration == 0) {
            revert InvalidArgument("Duration must be greater than zero blocks");
        }
        _;
    }

    modifier nonEmpty(string memory textName, string memory text) {
        if(bytes(text).length == 0) {
            revert InvalidArgument(string.concat(textName, " cannot be empty."));
        }
        _;
    }

    constructor(Organization orgs, AccountRulesV2 accs, AdminProxy adminsProxy) {
        if(address(orgs) == address(0)) {
            revert InvalidArgument("Invalid address for Organization management smart contract");
        }
        if(address(accs) == address(0)) {
            revert InvalidArgument("Invalid address for Account management smart contract");
        }
        if(address(adminsProxy) == address(0)) {
            revert InvalidArgument("Invalid address for Admin management smart contract");
        }
        organizations = orgs;
        accounts = accs;
        admins = adminsProxy;
    }

    function createProposal(address[] calldata targets, bytes[] memory calldatas, uint blocksDuration, string calldata description) public
        onlyActiveGlobalAdmin matchingCalls(targets.length, calldatas.length) validDuration(blocksDuration) nonEmpty("Description", description) returns (uint) {
        proposals.push(ProposalData(
            ++idSeed,
            accounts.getAccount(msg.sender).orgId,
            targets,
            calldatas,
            blocksDuration,
            description,
            block.number,
            ProposalStatus.Active,
            ProposalResult.Undefined,
            new uint[](0),
            new ProposalVote[](0),
            ""
        ));

        ProposalData storage proposal = proposals[idSeed - 1];
        Organization.OrganizationData[] memory allOrgs = organizations.getOrganizations();
        for(uint i = 0; i < allOrgs.length; ++i) {
            if(allOrgs[i].canVote) {
                proposal.organizations.push(allOrgs[i].id);
                proposal.votes.push(ProposalVote.NotVoted);
            }
        }
        assert(proposal.organizations.length == proposal.votes.length);

        emit ProposalCreated(proposal.id, targets, calldatas, blocksDuration, description);

        return proposal.id;
    }

    function cancelProposal(uint proposalId, string calldata reason) public onlyActiveGlobalAdminOrGovernance existentProposal(proposalId)
        onlyProponentOrganizationOrGovernance(proposalId) onlyActiveProposal(proposalId) nonEmpty("Cancelation reason", reason) {
        ProposalData storage proposal = _getProposal(proposalId);
        proposal.status = ProposalStatus.Canceled;
        proposal.cancelationReason = reason;
        emit ProposalCanceled(proposalId, reason);
    }

    function castVote(uint proposalId, bool approve) public onlyActiveGlobalAdmin existentProposal(proposalId) onlyActiveProposal(proposalId)
        onlyParticipantOrganization(proposalId) returns (bool) {
        ProposalData storage proposal = _getProposal(proposalId);
        AccountRulesV2.AccountData memory acc = accounts.getAccount(msg.sender);
        uint orgNdx = _getOrganizationIndex(proposal, acc.orgId);

        if(proposal.votes[orgNdx] != ProposalVote.NotVoted) {
            revert IllegalState("Organization has already voted");
        }

        if(_isFinished(proposal)) {
            return false;
        }

        if(approve) {
            proposal.votes[orgNdx] = ProposalVote.Approval;
        }
        else {
            proposal.votes[orgNdx] = ProposalVote.Rejection;
        }

        emit OrganizationVoted(proposalId, acc.orgId, approve);

        if(proposal.result == ProposalResult.Undefined) {
            _majorityAchieved(proposal);
        }

        return true;
    }

    function _getOrganizationIndex(ProposalData storage proposal, uint orgId) private view returns (uint) {
        uint ndx;
        for(ndx = 0; ndx < proposal.organizations.length && proposal.organizations[ndx] != orgId; ++ndx) { }
        return ndx;
    }

    function _isFinished(ProposalData storage proposal) private returns (bool) {
        if(block.number - proposal.creationBlock > proposal.blocksDuration) {
            // Duration of the proposal is exceeded
            _finishProposal(proposal);
            return true;
        }
        return false;
    }

    function _finishProposal(ProposalData storage proposal) private {
        proposal.status = ProposalStatus.Finished;
        emit ProposalFinished(proposal.id);
    }

    function _majorityAchieved(ProposalData storage proposal) private returns (bool) {
        uint majority = (proposal.organizations.length / 2) + 1;
        uint approvalVotes = 0;
        uint rejectionVotes = 0;

        for(uint i = 0; i < proposal.votes.length; ++i) {
            if(proposal.votes[i] == ProposalVote.Approval) {
                ++approvalVotes;
            }
            else if(proposal.votes[i] == ProposalVote.Rejection) {
                ++rejectionVotes;
            }
        }

        if(approvalVotes >= majority) {
            proposal.result = ProposalResult.Approved;
            emit ProposalApproved(proposal.id);
            return true;
        }

        if(rejectionVotes >= majority) {
            proposal.result = ProposalResult.Rejected;
            emit ProposalRejected(proposal.id);
            return true;
        }

        if(approvalVotes + rejectionVotes == proposal.organizations.length) {
            // Empate
            proposal.result = ProposalResult.Rejected;
            emit ProposalRejected(proposal.id);
        }

        return false;
    }

    function executeProposal(uint proposalId) public onlyActiveGlobalAdmin existentProposal(proposalId) 
        onlyActiveOrFinishedProposal(proposalId) onlyParticipantOrganization(proposalId) onlyDefinedProposal(proposalId)
        returns (bytes[] memory) {
        ProposalData storage proposal = _getProposal(proposalId);
        if(proposal.status != ProposalStatus.Finished) {
            _finishProposal(proposal);
        }

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(proposalId);

        bytes[] memory returnedValues = new bytes[](proposal.targets.length);
        for (uint i = 0; i < proposal.targets.length; ++i) {
            returnedValues[i] = Address.functionCall(proposal.targets[i], proposal.calldatas[i]);
        }

        return returnedValues;
    }

    function _getProposal(uint proposalId) private view returns (ProposalData storage) {
        ProposalData storage proposal = proposals[proposalId - 1];
        assert(proposal.id == proposalId);
        return proposal;
    }

    function getProposal(uint proposalId) public view existentProposal(proposalId) returns (ProposalData memory) {
        return _getProposal(proposalId);
    }

    function getNumberOfProposals() public view returns (uint) {
        return proposals.length;
    }

    function getProposals(uint pageNumber, uint pageSize) public view returns (ProposalData[] memory) {
        (uint start, uint stop) = Pagination.getPageBounds(proposals.length, pageNumber, pageSize);
        ProposalData[] memory props = new ProposalData[](stop - start);
        for(uint i = start; i < stop; ++i) {
            props[i - start] = proposals[i];
        }
        return props;
    }

}