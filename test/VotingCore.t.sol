// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
    address public user = address(0x2);

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
        token.mint(user, 10000 ether);
    }

    function test_OnlyAdminCanCreateVoting() public {
        uint256 deadline = block.timestamp + 7 days;
        uint256 threshold = 5000;
        string memory description = "Test proposal";

        vm.prank(user);
        vm.expectRevert();
        votingCore.createVoting(deadline, threshold, description);

        vm.prank(owner);
        bytes32 votingId = votingCore.createVoting(deadline, threshold, description);
        assertTrue(votingId != bytes32(0));
    }

    function test_CreateAndGetVoting() public {
        uint256 deadline = block.timestamp + 7 days;
        uint256 threshold = 5000;
        string memory description = "Test proposal";

        vm.prank(owner);
        bytes32 votingId = votingCore.createVoting(deadline, threshold, description);

        // getVoting возвращает 7 значений
        (uint256 d, uint256 t, string memory desc, uint256 yes, uint256 no, bool finalized, bool passed) = votingCore.getVoting(votingId);
        assertEq(d, deadline);
        assertEq(t, threshold);
        assertEq(desc, description);
        assertEq(yes, 0);
        assertEq(no, 0);
        assertFalse(finalized);
        assertFalse(passed);
    }
}
