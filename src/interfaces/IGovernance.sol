// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.28;

interface IGovernance {
    enum ProposalStatus {
        Active,
        Canceled,
        Finished,
        Executed
    }
    enum ProposalResult {
        Undefined,
        Approved,
        Rejected
    }
    enum ProposalVote {
        NotVoted,
        Approval,
        Rejection
    }

    struct ProposalData {
        uint256 id;
        uint256 proponentOrgId;
        address[] targets;
        bytes[] calldatas;
        uint256 blocksDuration;
        string description;
        uint256 creationBlock;
        ProposalStatus status;
        ProposalResult result;
        uint256[] organizations;
        ProposalVote[] votes;
        string cancelationReason;
    }

    event ProposalCreated(
        uint256 indexed proposalI, address[] targets, bytes[] calldatas, uint256 blocksDuration, string description
    );
    event OrganizationVoted(uint256 indexed proposalId, uint256 orgId, bool approve);
    event ProposalCanceled(uint256 indexed proposalId, string reason);
    event ProposalFinished(uint256 indexed proposalId);
    event ProposalApproved(uint256 indexed proposalId);
    event ProposalRejected(uint256 indexed proposalId);
    event ProposalExecuted(uint256 indexed proposalId);

    function idSeed() external view returns (uint256);
    function admins() external view returns (address);
    function organizations() external view returns (address);
    function accounts() external view returns (address);

    function proposals(uint256)
        external
        view
        returns (
            uint256 id,
            uint256 proponentOrgId,
            uint256 blocksDuration,
            string memory description,
            uint256 creationBlock,
            ProposalStatus status,
            ProposalResult result,
            string memory cancelationReason
        );

    function createProposal(
        address[] calldata targets,
        bytes[] calldata calldatas,
        uint256 blocksDuration,
        string calldata description
    ) external returns (uint256);

    function cancelProposal(uint256 proposalId, string calldata reason) external;

    function castVote(uint256 proposalId, bool approve) external returns (bool);

    function executeProposal(uint256 proposalId) external returns (bytes[] memory);

    function getProposal(uint256 proposalId) external view returns (ProposalData memory);

    function getNumberOfProposals() external view returns (uint256);

    function getProposals(uint256 pageNumber, uint256 pageSize) external view returns (ProposalData[] memory);
}
