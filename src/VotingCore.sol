// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./VotingStaking.sol";
import "./VoteResultNFT.sol";

contract VotingCore is Ownable, ReentrancyGuard, Pausable {
    VotingStaking public immutable staking;
    VoteResultNFT public immutable resultNFT;

    struct Voting {
        bytes32 id;
        uint256 deadline;
        uint256 votingPowerThreshold;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
        bool passed;
        mapping(address => bool) hasVoted;
        mapping(address => bool) voteChoice;
    }

    mapping(bytes32 => Voting) public votings;
    bytes32[] public votingIds;

    event VotingCreated(bytes32 indexed votingId, uint256 deadline, uint256 threshold, string description);
    event VoteCast(bytes32 indexed votingId, address indexed voter, bool support, uint256 votingPower);
    event VotingFinalized(bytes32 indexed votingId, bool passed, uint256 tokenId);

    constructor(address _staking, address _resultNFT, address initialOwner) Ownable(initialOwner) {
        staking = VotingStaking(_staking);
        resultNFT = VoteResultNFT(_resultNFT);
    }

    /**
     * @dev Create a new voting. Only callable by owner.
     * @param deadline Unix timestamp when voting ends
     * @param votingPowerThreshold Minimum yes votes needed to pass
     * @param description Description of the proposal
     */
    function createVoting(
        uint256 deadline,
        uint256 votingPowerThreshold,
        string memory description
    ) external onlyOwner whenNotPaused returns (bytes32) {
        require(deadline > block.timestamp, "Deadline must be in the future");
        require(votingPowerThreshold > 0, "Threshold must be greater than 0");

        bytes32 votingId = keccak256(abi.encodePacked(block.timestamp, description, votingIds.length));

        Voting storage newVoting = votings[votingId];
        newVoting.id = votingId;
        newVoting.deadline = deadline;
        newVoting.votingPowerThreshold = votingPowerThreshold;
        newVoting.description = description;
        newVoting.yesVotes = 0;
        newVoting.noVotes = 0;
        newVoting.finalized = false;

        votingIds.push(votingId);

        emit VotingCreated(votingId, deadline, votingPowerThreshold, description);
        return votingId;
    }

    /**
     * @dev Cast a vote on a voting
     * @param votingId The voting ID
     * @param support True for yes, false for no
     */
    function castVote(bytes32 votingId, bool support) external nonReentrant whenNotPaused {
        Voting storage voting = votings[votingId];
        require(voting.id != bytes32(0), "Voting does not exist");
        require(!voting.finalized, "Voting already finalized");
        require(block.timestamp <= voting.deadline, "Voting deadline passed");
        require(!voting.hasVoted[msg.sender], "Already voted");

        uint256 votingPower = staking.getVotingPower(msg.sender);
        require(votingPower > 0, "No voting power");

        voting.hasVoted[msg.sender] = true;
        voting.voteChoice[msg.sender] = support;

        if (support) {
            voting.yesVotes += votingPower;
        } else {
            voting.noVotes += votingPower;
        }

        emit VoteCast(votingId, msg.sender, support, votingPower);

        // Auto-finalize if threshold is met
        if (!voting.finalized && voting.yesVotes >= voting.votingPowerThreshold) {
            _finalizeVoting(votingId);
        }
    }

    /**
     * @dev Finalize a voting. Anyone can call if deadline passed.
     * @param votingId The voting ID
     */
    function finalizeVoting(bytes32 votingId) external nonReentrant {
        Voting storage voting = votings[votingId];
        require(voting.id != bytes32(0), "Voting does not exist");
        require(!voting.finalized, "Voting already finalized");
        require(block.timestamp > voting.deadline, "Deadline not reached");

        _finalizeVoting(votingId);
    }

    /**
     * @dev Internal function to finalize voting and mint NFT
     */
    function _finalizeVoting(bytes32 votingId) internal {
        Voting storage voting = votings[votingId];
        require(!voting.finalized, "Already finalized");

        bool passed = voting.yesVotes >= voting.votingPowerThreshold;
        voting.finalized = true;
        voting.passed = passed;

        // Mint NFT with results
        VoteResultNFT.ResultMetadata memory metadata = VoteResultNFT.ResultMetadata({
            votingId: votingId,
            description: voting.description,
            yesVotes: voting.yesVotes,
            noVotes: voting.noVotes,
            threshold: voting.votingPowerThreshold,
            passed: passed,
            finalizedAt: block.timestamp
        });

        uint256 tokenId = resultNFT.mint(msg.sender, metadata);

        emit VotingFinalized(votingId, passed, tokenId);
    }

    /**
     * @dev Get voting details
     */
    function getVoting(bytes32 votingId) external view returns (
        uint256 deadline,
        uint256 threshold,
        string memory description,
        uint256 yesVotes,
        uint256 noVotes,
        bool finalized,
        bool passed
    ) {
        Voting storage voting = votings[votingId];
        require(voting.id != bytes32(0), "Voting does not exist");
        return (
            voting.deadline,
            voting.votingPowerThreshold,
            voting.description,
            voting.yesVotes,
            voting.noVotes,
            voting.finalized,
            voting.passed
        );
    }

    /**
     * @dev Check if user voted and their choice
     */
    function getUserVote(bytes32 votingId, address user) external view returns (bool hasVoted, bool voteChoice) {
        Voting storage voting = votings[votingId];
        return (voting.hasVoted[user], voting.voteChoice[user]);
    }

    /**
     * @dev Get total number of votings
     */
    function getVotingCount() external view returns (uint256) {
        return votingIds.length;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}