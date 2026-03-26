// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VVToken.sol";
import "../src/VotingStaking.sol";
import "../src/VoteResultNFT.sol";
import "../src/VotingCore.sol";

contract VotingCoreTest is Test {
    VVToken public token;
    VotingStaking public staking;
    VoteResultNFT public resultNFT;
    VotingCore public votingCore;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public user3 = address(0x4);

    uint256 public constant YEAR = 365 days;

    function setUp() public {
        vm.prank(owner);
        token = new VVToken(owner);

        vm.prank(owner);
        staking = new VotingStaking(address(token), owner);

        vm.prank(owner);
        resultNFT = new VoteResultNFT(owner);

        vm.prank(owner);
        votingCore = new VotingCore(address(staking), address(resultNFT), owner);

        vm.prank(owner);
        resultNFT.transferOwnership(address(votingCore));

        // Mint tokens to users
        vm.prank(owner);
        token.mint(user1, 10000 ether);
        vm.prank(owner);
        token.mint(user2, 10000 ether);
        vm.prank(owner);
        token.mint(user3, 10000 ether);
    }

    function _setupStakes() internal {
        vm.startPrank(user1);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 2);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(staking), 500 ether);
        staking.stake(500 ether, 1);
        vm.stopPrank();

        vm.startPrank(user3);
        token.approve(address(staking), 2000 ether);
        staking.stake(2000 ether, 3);
        vm.stopPrank();
    }

    function _createVoting() internal returns (bytes32) {
        uint256 deadline = block.timestamp + 7 days;
        uint256 threshold = 5000;
        string memory description = "Should we increase rewards?";
        vm.prank(owner);
        return votingCore.createVoting(deadline, threshold, description);
    }

    // Test: Create voting only by admin
    function test_OnlyAdminCanCreateVoting() public {
        uint256 deadline = block.timestamp + 7 days;
        uint256 threshold = 5000;
        string memory description = "Test proposal";

        vm.prank(user1);
        vm.expectRevert();
        votingCore.createVoting(deadline, threshold, description);

        vm.prank(owner);
        bytes32 votingId = votingCore.createVoting(deadline, threshold, description);
        assertTrue(votingId != bytes32(0));
    }

    function test_CreateVotingInvalidDeadline() public {
        uint256 deadline = block.timestamp - 1;
        uint256 threshold = 5000;
        string memory description = "Test proposal";

        vm.prank(owner);
        vm.expectRevert("Deadline must be in the future");
        votingCore.createVoting(deadline, threshold, description);
    }

    function test_CreateVotingZeroThreshold() public {
        uint256 deadline = block.timestamp + 7 days;
        uint256 threshold = 0;
        string memory description = "Test proposal";

        vm.prank(owner);
        vm.expectRevert("Threshold must be greater than 0");
        votingCore.createVoting(deadline, threshold, description);
    }

    // Test: Voting with power check
    function test_CastVoteWithVotingPower() public {
        _setupStakes();
        bytes32 votingId = _createVoting();

        // User1 has 4000 VP (2^2 * 1000)
        vm.prank(user1);
        votingCore.castVote(votingId, true);

        (,,, uint256 yesVotes, uint256 noVotes,,) = votingCore.getVoting(votingId);
        assertEq(yesVotes, 4000);
        assertEq(noVotes, 0);

        // User2 has 500 VP (1^2 * 500)
        vm.prank(user2);
        votingCore.castVote(votingId, false);

        (,,, yesVotes, noVotes,,) = votingCore.getVoting(votingId);
        assertEq(yesVotes, 4000);
        assertEq(noVotes, 500);
    }

    function test_CannotVoteTwice() public {
        _setupStakes();
        bytes32 votingId = _createVoting();

        vm.prank(user1);
        votingCore.castVote(votingId, true);

        vm.prank(user1);
        vm.expectRevert("Already voted");
        votingCore.castVote(votingId, false);
    }

    function test_CannotVoteAfterDeadline() public {
        _setupStakes();
        bytes32 votingId = _createVoting();

        vm.warp(block.timestamp + 8 days);

        vm.prank(user1);
        vm.expectRevert("Voting deadline passed");
        votingCore.castVote(votingId, true);
    }

    function test_CannotVoteWithNoVotingPower() public {
        // User without stake tries to vote
        bytes32 votingId = _createVoting();

        vm.prank(user1);
        vm.expectRevert("No voting power");
        votingCore.castVote(votingId, true);
    }

    // Test: Early finalization when threshold met
    function test_EarlyFinalizationWhenThresholdMet() public {
        _setupStakes();
        uint256 threshold = 4000; // Exactly user1's VP
        uint256 deadline = block.timestamp + 7 days;
        vm.prank(owner);
        bytes32 votingId = votingCore.createVoting(deadline, threshold, "Test");

        vm.prank(user1);
        votingCore.castVote(votingId, true);

        // Should auto-finalize when threshold met
        (,,, uint256 yesVotes,, bool finalized, bool passed) = votingCore.getVoting(votingId);
        assertEq(yesVotes, 4000);
        assertTrue(finalized);
        assertTrue(passed);

        // Verify NFT was minted
        uint256 tokenId = resultNFT.votingIdToTokenId(votingId);
        assertTrue(tokenId != 0);
    }

    function test_NoEarlyFinalizationBelowThreshold() public {
        _setupStakes();
        uint256 threshold = 5000;
        uint256 deadline = block.timestamp + 7 days;
        vm.prank(owner);
        bytes32 votingId = votingCore.createVoting(deadline, threshold, "Test");

        vm.prank(user1);
        votingCore.castVote(votingId, true); // 4000 VP, below threshold

        (,,, uint256 yesVotes,, bool finalized,) = votingCore.getVoting(votingId);
        assertEq(yesVotes, 4000);
        assertFalse(finalized);
    }

    // Test: Finalization by deadline
    function test_FinalizationByDeadline() public {
        _setupStakes();
        bytes32 votingId = _createVoting();

        vm.prank(user1);
        votingCore.castVote(votingId, true);

        vm.prank(user2);
        votingCore.castVote(votingId, false);

        // Warp past deadline
        vm.warp(block.timestamp + 8 days);

        // Anyone can finalize
        vm.prank(user3);
        votingCore.finalizeVoting(votingId);

        (,,,,, bool finalized, bool passed) = votingCore.getVoting(votingId);
        assertTrue(finalized);
        // 4000 yes vs 500 no, threshold was 5000, so not passed
        assertFalse(passed);

        // Verify NFT was minted
        uint256 tokenId = resultNFT.votingIdToTokenId(votingId);
        assertTrue(tokenId != 0);
    }

    function test_CannotFinalizeBeforeDeadline() public {
        _setupStakes();
        bytes32 votingId = _createVoting();

        vm.prank(user1);
        votingCore.castVote(votingId, true);

        vm.prank(user3);
        vm.expectRevert("Deadline not reached");
        votingCore.finalizeVoting(votingId);
    }

    function test_CannotFinalizeTwice() public {
        _setupStakes();
        bytes32 votingId = _createVoting();

        vm.prank(user1);
        votingCore.castVote(votingId, true);

        vm.warp(block.timestamp + 8 days);

        vm.prank(user3);
        votingCore.finalizeVoting(votingId);

        vm.prank(user3);
        vm.expectRevert("Voting already finalized");
        votingCore.finalizeVoting(votingId);
    }

    // Test: NFT mint after finalization
    function test_NFTMintedWithCorrectMetadata() public {
        _setupStakes();
        uint256 deadline = block.timestamp + 7 days;
        uint256 threshold = 5000;
        string memory description = "Test NFT metadata";
        vm.prank(owner);
        bytes32 votingId = votingCore.createVoting(deadline, threshold, description);

        vm.prank(user1);
        votingCore.castVote(votingId, true); // 4000 yes
        vm.prank(user2);
        votingCore.castVote(votingId, false); // 500 no

        vm.warp(block.timestamp + 8 days);
        vm.prank(user3);
        votingCore.finalizeVoting(votingId);

        uint256 tokenId = resultNFT.votingIdToTokenId(votingId);
        VoteResultNFT.ResultMetadata memory metadata = resultNFT.results(tokenId);

        assertEq(metadata.votingId, votingId);
        assertEq(metadata.description, description);
        assertEq(metadata.yesVotes, 4000);
        assertEq(metadata.noVotes, 500);
        assertEq(metadata.threshold, threshold);
        assertFalse(metadata.passed);
        assertTrue(metadata.finalizedAt > 0);

        // Check tokenURI exists
        string memory uri = resultNFT.tokenURI(tokenId);
        assertTrue(bytes(uri).length > 0);
    }

    // Test: Get user vote
    function test_GetUserVote() public {
        _setupStakes();
        bytes32 votingId = _createVoting();

        vm.prank(user1);
        votingCore.castVote(votingId, true);

        (bool hasVoted, bool choice) = votingCore.getUserVote(votingId, user1);
        assertTrue(hasVoted);
        assertTrue(choice);

        (hasVoted, choice) = votingCore.getUserVote(votingId, user2);
        assertFalse(hasVoted);
        assertFalse(choice);
    }

    // Test: Pause functionality
    function test_PausePreventsVoting() public {
        _setupStakes();
        bytes32 votingId = _createVoting();

        vm.prank(owner);
        votingCore.pause();

        vm.prank(user1);
        vm.expectRevert();
        votingCore.castVote(votingId, true);
    }

    function test_UnpauseRestoresVoting() public {
        _setupStakes();
        bytes32 votingId = _createVoting();

        vm.prank(owner);
        votingCore.pause();

        vm.prank(owner);
        votingCore.unpause();

        vm.prank(user1);
        votingCore.castVote(votingId, true);

        (,,, uint256 yesVotes,,,) = votingCore.getVoting(votingId);
        assertEq(yesVotes, 4000);
    }
}