// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VVToken.sol";

contract VVTokenTest is Test {
    VVToken public token;
    address public owner = address(0x1);
    address public user = address(0x2);

    function setUp() public {
        vm.prank(owner);
        token = new VVToken(owner);
    }

    function test_InitialState() public view {
        assertEq(token.name(), "VegaVoting");
        assertEq(token.symbol(), "VV");
        assertEq(token.decimals(), 18);
        assertEq(token.owner(), owner);
    }

    function test_OnlyOwnerCanMint() public {
        vm.prank(owner);
        token.mint(user, 1000 ether);
        assertEq(token.balanceOf(user), 1000 ether);

        vm.prank(user);
        vm.expectRevert();
        token.mint(user, 1000 ether);
    }

    function test_UserCanBurn() public {
        vm.prank(owner);
        token.mint(user, 1000 ether);

        vm.prank(user);
        token.burn(500 ether);
        assertEq(token.balanceOf(user), 500 ether);
    }

    function test_OwnerCanPause() public {
        vm.prank(owner);
        token.pause();

        vm.prank(owner);
        vm.expectRevert();
        token.mint(user, 1000 ether);
    }

    function test_OwnerCanUnpause() public {
        vm.prank(owner);
        token.pause();

        vm.prank(owner);
        token.unpause();

        vm.prank(owner);
        token.mint(user, 1000 ether);
        assertEq(token.balanceOf(user), 1000 ether);
    }
}