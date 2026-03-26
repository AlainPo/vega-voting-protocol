// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VVToken.sol";
import "../src/VotingStaking.sol";
import "../src/VoteResultNFT.sol";
import "../src/VotingCore.sol";

contract IntegrationTest is Test {
    VVToken public token;
    VotingStaking public staking;
    VoteResultNFT public resultNFT;
    VotingCore public votingCore;

    address public owner = address(0x1);
    address public alice = address(0x2);
    address public bob = address(0x3);
    address public charlie = address(0x4);

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
        token.mint(alice, 10000 ether);
        vm.prank(owner);
        token.mint(bob, 10000 ether);
        vm.prank(owner);
        token.mint(charlie, 10000 ether);
    }

    function test_FullWorkflow() public {
        // 1. Users stake tokens
        vm.startPrank(alice);
        token.approve(address(staking), 2000 ether);
        staking.stake(2000 ether, 3); // 3 years: VP = 9 * 2000 = 18000
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(staking), 1500 ether);
        staking.stake(1500 ether, 2); // 2 years: VP = 4 * 1500 = 6000
        vm.stopPrank();

        vm.startPrank(charlie);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 1); // 1 year: VP = 1 * 1000 = 1000
        vm.stopPrank();

        // 2. Check voting powers
        assertEq(staking.getVotingPower(alice), 18000);
        assertEq(staking.getVotingPower(bob), 6000);
        assertEq(staking.getVotingPower(charlie), 1000);

        // 3. Admin creates a vote
        uint256 deadline = block.timestamp + 7 days;
        uint256 threshold = 15000;
        string memory description = "Should we approve the new treasury proposal?";
        vm.prank(owner);
        bytes32 votingId = votingCore.createVoting(deadline, threshold, description);

        // 4. Users vote
        vm.prank(alice);
        votingCore.castVote(votingId, true); // 18000 yes

        vm.prank(bob);
        votingCore.castVote(votingId, false); // 6000 no

        // 5. Threshold is met (18000 >= 15000), auto-finalize
        (,,, uint256 yesVotes, uint256 noVotes, bool finalized, bool passed) = votingCore.getVoting(votingId);
        assertEq(yesVotes, 18000);
        assertEq(noVotes, 6000);
        assertTrue(finalized);
        assertTrue(passed);

        // 6. NFT was minted
        uint256 tokenId = resultNFT.votingIdToTokenId(votingId);
        assertTrue(tokenId != 0);

        // 7. Check NFT metadata
        VoteResultNFT.ResultMetadata memory metadata = resultNFT.results(tokenId);
        assertEq(metadata.votingId, votingId);
        assertEq(metadata.description, description);
        assertEq(metadata.yesVotes, 18000);
        assertEq(metadata.noVotes, 6000);
        assertEq(metadata.threshold, threshold);
        assertTrue(metadata.passed);

        // 8. Charlie couldn't vote because vote already finalized
        vm.prank(charlie);
        vm.expectRevert("Voting already finalized");
        votingCore.castVote(votingId, true);
    }

    function test_WorkflowWithDeadlineFinalization() public {
        // 1. Users stake
        vm.startPrank(alice);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 2);
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 2);
        vm.stopPrank();

        // 2. Create vote with high threshold
        uint256 deadline = block.timestamp + 7 days;
        uint256 threshold = 10000; // Higher than total VP (4000 + 4000 = 8000)
        string memory description = "High threshold proposal";
        vm.prank(owner);
        bytes32 votingId = votingCore.createVoting(deadline, threshold, description);

        // 3. Both vote yes
        vm.prank(alice);
        votingCore.castVote(votingId, true); // 4000 yes
        vm.prank(bob);
        votingCore.castVote(votingId, true); // 8000 yes total

        // 4. Threshold not met, not finalized
        (,,, uint256 yesVotes,, bool finalized,) = votingCore.getVoting(votingId);
        assertEq(yesVotes, 8000);
        assertFalse(finalized);

        // 5. Warp past deadline
        vm.warp(block.timestamp + 8 days);

        // 6. Finalize
        vm.prank(charlie);
        votingCore.finalizeVoting(votingId);

        (,,,,, finalized, bool passed) = votingCore.getVoting(votingId);
        assertTrue(finalized);
        assertFalse(passed); // Threshold not met

        // 7. NFT minted with correct results
        uint256 tokenId = resultNFT.votingIdToTokenId(votingId);
        VoteResultNFT.ResultMetadata memory metadata = resultNFT.results(tokenId);
        assertEq(metadata.yesVotes, 8000);
        assertEq(metadata.noVotes, 0);
        assertFalse(metadata.passed);
    }

    function test_VotingPowerChangesOverTime() public {
        // 1. Alice stakes for 2 years
        vm.startPrank(alice);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 2);
        vm.stopPrank();

        // 2. Create vote with deadline 1 year from now
        uint256 deadline = block.timestamp + 1 * YEAR;
        uint256 threshold = 2000;
        string memory description = "Long term vote";
        vm.prank(owner);
        bytes32 votingId = votingCore.createVoting(deadline, threshold, description);

        // 3. Vote immediately - VP = 4 * 1000 = 4000
        vm.prank(alice);
        votingCore.castVote(votingId, true);

        (,,, uint256 yesVotes,,,) = votingCore.getVoting(votingId);
        assertEq(yesVotes, 4000);
        assertTrue(yesVotes >= threshold); // Auto-finalized

        // 4. Verify NFT was minted
        uint256 tokenId = resultNFT.votingIdToTokenId(votingId);
        assertTrue(tokenId != 0);
    }

    function test_MultipleStakesPerUser() public {
        // Alice makes multiple stakes
        vm.startPrank(alice);
        token.approve(address(staking), 3000 ether);
        staking.stake(1000 ether, 3); // 9 * 1000 = 9000
        staking.stake(2000 ether, 1); // 1 * 2000 = 2000
        // Total VP = 11000
        vm.stopPrank();

        // Create vote
        uint256 deadline = block.timestamp + 7 days;
        uint256 threshold = 10000;
        vm.prank(owner);
        bytes32 votingId = votingCore.createVoting(deadline, threshold, "Multiple stakes test");

        // Alice votes
        vm.prank(alice);
        votingCore.castVote(votingId, true);

        // Should pass threshold (11000 >= 10000)
        (,,, uint256 yesVotes,, bool finalized, bool passed) = votingCore.getVoting(votingId);
        assertEq(yesVotes, 11000);
        assertTrue(finalized);
        assertTrue(passed);
    }

    function test_WithdrawAfterVote() public {
        // Setup and vote
        vm.startPrank(alice);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 1);
        vm.stopPrank();

        uint256 deadline = block.timestamp + 7 days;
        vm.prank(owner);
        bytes32 votingId = votingCore.createVoting(deadline, 500, "Test");

        vm.prank(alice);
        votingCore.castVote(votingId, true);

        // Warp past stake expiry
        vm.warp(block.timestamp + 1 * YEAR + 1);

        // Withdraw stake
        vm.prank(alice);
        staking.withdraw(0);

        // Verify stake is withdrawn
        assertEq(staking.getTotalStaked(alice), 0);
        assertEq(staking.getVotingPower(alice), 0);

        // Voting result is already finalized and NFT exists
        uint256 tokenId = resultNFT.votingIdToTokenId(votingId);
        assertTrue(tokenId != 0);
    }
}