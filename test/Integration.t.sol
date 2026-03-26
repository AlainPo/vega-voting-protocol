// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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

        vm.prank(owner);
        token.mint(alice, 10000 ether);
    }

    function test_SimpleStake() public {
        vm.startPrank(alice);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 2);
        uint256 vp = staking.getVotingPower(alice);
        assertEq(vp, 4000);
        vm.stopPrank();
    }

    function test_SimpleVote() public {
        vm.startPrank(alice);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 2);
        vm.stopPrank();

        uint256 deadline = block.timestamp + 7 days;
        uint256 threshold = 4000;
        vm.prank(owner);
        bytes32 votingId = votingCore.createVoting(deadline, threshold, "Test vote");

        vm.prank(alice);
        votingCore.castVote(votingId, true);

        // getVoting возвращает 7 значений: deadline, threshold, description, yesVotes, noVotes, finalized, passed
        (,,, uint256 yesVotes, uint256 noVotes, bool finalized, bool passed) = votingCore.getVoting(votingId);
        assertEq(yesVotes, 4000);
        assertEq(noVotes, 0);
        assertTrue(finalized);
        assertTrue(passed);
    }
}
