// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IHousingNFT {
    function tokenBalance(address account) external view returns (uint256);
 
}

contract HousingSociety is ReentrancyGuard {
    uint256 immutable MaintenanceAmount  = 0.01 ether;
    // uint32 immutable MIN_VOTE_DURATION = 1 weeks;
    uint32 immutable MIN_VOTE_DURATION = 3 minutes;
    uint256 totalProposals;
    uint256 public daoBalance;

    mapping(uint256 => ProposalStruct) private raisedProposals;
    mapping(address => uint256[]) private stakeholderVotes;
    mapping(uint256 => VotedStruct[]) private votedOn;
    mapping(address => uint256) private stakeholders;

    struct ProposalStruct {
        uint256 id;
        uint256 amount;
        uint256 duration;
        uint256 upvotes;
        uint256 downvotes;
        string title;
        string description;
        bool passed;
        bool paid;
        address payable beneficiary;
        address proposer;
        address executor;
    }

    struct VotedStruct {
        address voter;
        uint256 timestamp;
        bool choosen;
    }

    event Action(
        address indexed initiator,
        // bytes32 role,
        string message,
        address indexed beneficiary,
        uint256 amount
    );

    IHousingNFT housingNFT;

    constructor(address _housingNFT) payable {
        housingNFT = IHousingNFT(_housingNFT);
    }

    modifier nftHolder () {
        require(housingNFT.tokenBalance(msg.sender) > 0, "You do not have House!");
        _;
    }


    function createProposal(
        string calldata title,
        string calldata description,
        address beneficiary,
        uint256 amount
    )
        
        external
        nftHolder
        returns (ProposalStruct memory)
    {
        uint256 proposalId = totalProposals++;
        ProposalStruct storage proposal = raisedProposals[proposalId];

        proposal.id = proposalId;
        proposal.proposer = payable(msg.sender);
        proposal.title = title;
        proposal.description = description;
        proposal.beneficiary = payable(beneficiary);
        proposal.amount = amount;
        proposal.duration = block.timestamp + MIN_VOTE_DURATION;

        emit Action(
            msg.sender,
            "PROPOSAL RAISED",
            beneficiary,
            amount
        );

        return proposal;
    }

    function performVote(
        uint256 proposalId,
        bool choosen
    )
        external
        nftHolder
        returns (VotedStruct memory)
    {
        ProposalStruct storage proposal = raisedProposals[proposalId];
        uint256 voterNFTBalance = housingNFT.tokenBalance(msg.sender);
        handleVoting(proposal);

        if (choosen) 
        {proposal.upvotes += voterNFTBalance;}
        else proposal.downvotes += voterNFTBalance;

        stakeholderVotes[msg.sender].push(proposal.id);

        votedOn[proposal.id].push(
            VotedStruct(msg.sender, block.timestamp, choosen)
        );

        emit Action(
            msg.sender,
            "PROPOSAL VOTE",
            proposal.beneficiary,
            proposal.amount
        );

        return VotedStruct(msg.sender, block.timestamp, choosen);
    }

    function handleVoting(ProposalStruct storage proposal) private {
        if (proposal.passed || proposal.duration <= block.timestamp) {
            proposal.passed = true;
            revert("Proposal duration expired");
        }

        uint256[] memory tempVotes = stakeholderVotes[msg.sender];
        for (uint256 votes = 0; votes < tempVotes.length; votes++) {
            if (proposal.id == tempVotes[votes])
                revert("Double voting not allowed");
        }
    }

    function payBeneficiary(
        uint256 proposalId
    )
        external
        nftHolder
        nonReentrant
        returns (uint256)
    {
        ProposalStruct storage proposal = raisedProposals[proposalId];
        require(proposal.proposer == msg.sender, "You are not proposer!");
        require(daoBalance >= proposal.amount, "Insufficient fund");

        if (proposal.paid) revert("Payment sent before");

        if (proposal.upvotes <= proposal.downvotes)
            revert("Insufficient votes");

        payTo(proposal.beneficiary, proposal.amount);

        proposal.paid = true;
        proposal.executor = msg.sender;
        daoBalance -= proposal.amount;

        emit Action(
            msg.sender,
            "PAYMENT TRANSFERED",
            proposal.beneficiary,
            proposal.amount
        );

        return daoBalance;
    }

    function payMaintenance() external payable returns (uint256)
    {
        require(msg.value > MaintenanceAmount, "fees cannot be zero!");
        stakeholders[msg.sender] += msg.value;
        daoBalance+= msg.value;

        return daoBalance;

    }

    function returnTokenBalance(address account) public view returns(uint256)
    {
        uint256 bal = housingNFT.tokenBalance(account);
        return bal;
    }

    function getProposals()
        external
        view
        returns (ProposalStruct[] memory props)
    {
        props = new ProposalStruct[](totalProposals);

        for (uint256 i = 0; i < totalProposals; i++) {
            props[i] = raisedProposals[i];
        }
    }

    function getProposal(
        uint256 proposalId
    ) external view returns (ProposalStruct memory) {
        return raisedProposals[proposalId];
    }

    function getVotesOf(
        uint256 proposalId
    ) external view returns (VotedStruct[] memory) {
        return votedOn[proposalId];
    }

    function getStakeholderVotes()
        external
        view
        // stakeholderOnly("Unauthorized: not a stakeholder")
        returns (uint256[] memory)
    {
        return stakeholderVotes[msg.sender];
    }

    function getStakeholderBalance()
        external
        view
        // stakeholderOnly("Unauthorized: not a stakeholder")
        returns (uint256)
    {
        return stakeholders[msg.sender];
    }

    function isStakeholder() external view returns (bool) {
        return stakeholders[msg.sender] > 0;
    }


    function payTo(address to, uint256 amount) internal returns (bool) {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Payment failed");
        return true;
    }
}