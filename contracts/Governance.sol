// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GovernanceToken is ERC20 {
    constructor() ERC20("GovernanceToken", "GVT") {
        _mint(msg.sender, 10 ether);
    }
}

contract Governance {
    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    struct Proposal {
        uint256 votingStarts;
        uint256 votingEnds;
        bool executed;
    }

    enum VoteType {
        AgainstProposal,
        ForProposal,
        Abstain
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Defeated,
        Executed
    }

    uint8 public constant VOTING_DELAY = 10;
    uint16 public constant VOTING_DURATION = 60;

    IERC20 public immutable i_token;

    mapping(bytes32 => Proposal) public s_proposals;
    mapping(bytes32 => ProposalVote) public s_proposalVotes;

    constructor(IERC20 _token) {
        i_token = _token;
    }

    function execute(
        address _to,
        uint256 _value,
        string calldata _func,
        bytes calldata _data,
        string calldata _description
    ) external payable {
        bytes32 proposalId = generateHash(
            _to,
            _value,
            _func,
            _data,
            keccak256(bytes(_description))
        );

        require(state(proposalId) == ProposalState.Succeeded, "Invalid state");
        Proposal storage proposal = s_proposals[proposalId];
        proposal.executed = true;

        bytes memory data;
        if (bytes(_func).length > 0) {
            data = abi.encodeWithSignature(_func, _data);
        } else {
            data = _data;
        }

        (bool success, ) = _to.call{value: _value}(data);

        require(success, "Call failed");
    }

    function propose(
        address _to,
        uint256 _value,
        string calldata _func,
        bytes calldata _data,
        string calldata _description
    ) external returns (bytes32) {
        require(i_token.balanceOf(msg.sender) > 0, "Not enough token");
        bytes32 proposalId = generateHash(
            _to,
            _value,
            _func,
            _data,
            keccak256(bytes(_description))
        );

        require(
            s_proposals[proposalId].votingStarts == 0,
            "Proposal already exists"
        );

        s_proposals[proposalId] = Proposal({
            votingStarts: block.timestamp + VOTING_DELAY,
            votingEnds: block.timestamp + VOTING_DURATION,
            executed: false
        });
        return proposalId;
    }

    function vote(bytes32 _proposalId, VoteType _voteType) external {
        require(state(_proposalId) == ProposalState.Active, "Invalid state");
        uint256 votingPower = i_token.balanceOf(msg.sender);
        require(votingPower > 0, "Not enough tokens");

        require(
            s_proposals[_proposalId].votingStarts == 0,
            "Proposal does not exist"
        );
        ProposalVote storage proposalVote = s_proposalVotes[_proposalId];
        require(!proposalVote.hasVoted[msg.sender], "Already voted");

        if (_voteType == VoteType.AgainstProposal) {
            proposalVote.againstVotes += votingPower;
        } else if (_voteType == VoteType.ForProposal) {
            proposalVote.forVotes += votingPower;
        } else {
            proposalVote.abstainVotes += votingPower;
        }

        proposalVote.hasVoted[msg.sender] = true;
    }

    function state(bytes32 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = s_proposals[_proposalId];
        require(proposal.votingStarts == 0, "Proposal does not exist");
        ProposalVote storage proposalVote = s_proposalVotes[_proposalId];

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (block.timestamp < proposal.votingStarts) {
            return ProposalState.Pending;
        }

        if (
            block.timestamp >= proposal.votingStarts &&
            block.timestamp < proposal.votingEnds
        ) {
            return ProposalState.Active;
        }

        if (proposalVote.forVotes > proposalVote.againstVotes) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    function generateHash(
        address _to,
        uint256 _value,
        string calldata _func,
        bytes calldata _data,
        bytes32 _descriptionHash
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(_to, _value, _func, _data, _descriptionHash));
    }
}
