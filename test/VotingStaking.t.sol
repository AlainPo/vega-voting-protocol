// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VVToken.sol";
import "../src/VotingStaking.sol";

contract VotingStakingTest is Test {
    VVToken public token;
    VotingStaking public staking;
    address public owner = address(0x1);
    address public user = address(0x2);
    address public user2 = address(0x3);

    uint256 public constant YEAR = 365 days;

    function setUp() public {
        vm.prank(owner);
        token = new VVToken(owner);

        vm.prank(owner);
        staking = new VotingStaking(address(token), owner);

        // Mint tokens to users
        vm.prank(owner);
        token.mint(user, 10000 ether);
        vm.prank(owner);
        token.mint(user2, 10000 ether);
    }

    function test_Stake() public {
        vm.startPrank(user);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 2);

        assertEq(staking.getTotalStaked(user), 1000 ether);
        assertEq(staking.getStakeCount(user), 1);
        assertEq(staking.getRemainingDuration(user, 0), 2 * YEAR);
        vm.stopPrank();
    }

    function test_StakeInvalidDuration() public {
        vm.startPrank(user);
        token.approve(address(staking), 1000 ether);

        vm.expectRevert("Duration must be between 1 and 4 years");
        staking.stake(1000 ether, 0);

        vm.expectRevert("Duration must be between 1 and 4 years");
        staking.stake(1000 ether, 5);
        vm.stopPrank();
    }

    function test_StakeZeroAmount() public {
        vm.startPrank(user);
        token.approve(address(staking), 0);

        vm.expectRevert("Amount must be greater than 0");
        staking.stake(0, 2);
        vm.stopPrank();
    }

    function test_WithdrawAfterExpiry() public {
        vm.startPrank(user);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 1);

        // Warp to after expiry
        vm.warp(block.timestamp + 1 * YEAR + 1);

        uint256 balanceBefore = token.balanceOf(user);
        staking.withdraw(0);
        uint256 balanceAfter = token.balanceOf(user);

        assertEq(balanceAfter - balanceBefore, 1000 ether);
        assertEq(staking.getTotalStaked(user), 0);
        vm.stopPrank();
    }

    function test_CannotWithdrawBeforeExpiry() public {
        vm.startPrank(user);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 2);

        vm.expectRevert("Stake still active");
        staking.withdraw(0);
        vm.stopPrank();
    }

    function test_StakeMultipleTimes() public {
        vm.startPrank(user);
        token.approve(address(staking), 3000 ether);
        staking.stake(1000 ether, 2);
        staking.stake(2000 ether, 3);

        assertEq(staking.getStakeCount(user), 2);
        assertEq(staking.getTotalStaked(user), 3000 ether);
        assertEq(staking.getRemainingDuration(user, 0), 2 * YEAR);
        assertEq(staking.getRemainingDuration(user, 1), 3 * YEAR);
        vm.stopPrank();
    }

    function test_VotingPowerCalculation() public {
        vm.startPrank(user);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 2);

        // Initial voting power: (2 years)^2 * 1000 / 1^2 = 4 * 1000 = 4000
        uint256 vp = staking.getVotingPower(user);
        assertEq(vp, 4 * 1000);

        // Warp 1 year later: remaining = 1 year, vp = 1^2 * 1000 = 1000
        vm.warp(block.timestamp + 1 * YEAR);
        vp = staking.getVotingPower(user);
        assertEq(vp, 1 * 1000);

        // Warp almost to expiry: remaining ~0, vp = 0
        vm.warp(block.timestamp + 1 * YEAR - 1);
        vp = staking.getVotingPower(user);
        assertEq(vp, 0);
        vm.stopPrank();
    }

    function test_VotingPowerMultipleStakes() public {
        vm.startPrank(user);
        token.approve(address(staking), 3000 ether);
        staking.stake(1000 ether, 2); // 4 * 1000 = 4000
        staking.stake(2000 ether, 1); // 1 * 2000 = 2000
        // Total = 6000

        uint256 vp = staking.getVotingPower(user);
        assertEq(vp, 4000 + 2000);

        // After 6 months: first stake remaining 1.5 years, second stake remaining 0.5 years
        vm.warp(block.timestamp + 180 days);
        // First: 1.5^2 = 2.25, 2.25 * 1000 = 2250
        // Second: 0.5^2 = 0.25, 0.25 * 2000 = 500
        // Total = 2750
        uint256 expected = (2250 + 500);
        assertEq(staking.getVotingPower(user), expected);
        vm.stopPrank();
    }

    function test_WithdrawnStakeNoVotingPower() public {
        vm.startPrank(user);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 1);
        vm.warp(block.timestamp + 1 * YEAR + 1);
        staking.withdraw(0);

        uint256 vp = staking.getVotingPower(user);
        assertEq(vp, 0);
        vm.stopPrank();
    }

    function test_OnlyOwnerCanPause() public {
        vm.prank(user);
        vm.expectRevert();
        staking.pause();

        vm.prank(owner);
        staking.pause();

        vm.startPrank(user);
        token.approve(address(staking), 1000 ether);
        vm.expectRevert();
        staking.stake(1000 ether, 2);
        vm.stopPrank();
    }
}