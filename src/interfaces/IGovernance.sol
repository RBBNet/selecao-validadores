// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.28;

interface IGovernance {
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

    function idSeed() external view returns (uint);
    function admins() external view returns (address);
    function organizations() external view returns (address);
    function accounts() external view returns (address); 
    
    function proposals(uint256) external view returns (
        uint id,
        uint proponentOrgId,
        uint blocksDuration,
        string memory description,
        uint creationBlock,
        ProposalStatus status,
        ProposalResult result,
        string memory cancelationReason
    );

    function createProposal(
        address[] calldata targets,
        bytes[] calldata calldatas,
        uint blocksDuration,
        string calldata description
    ) external returns (uint);

    function cancelProposal(
        uint proposalId,
        string calldata reason
    ) external;

    function castVote(
        uint proposalId,
        bool approve
    ) external returns (bool);

    function executeProposal(
        uint proposalId
    ) external returns (bytes[] memory);


    function getProposal(
        uint proposalId
    ) external view returns (ProposalData memory);

    function getNumberOfProposals() external view returns (uint);

    function getProposals(
        uint pageNumber,
        uint pageSize
    ) external view returns (ProposalData[] memory);
}