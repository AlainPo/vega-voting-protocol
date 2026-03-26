// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VVToken.sol";
import "../src/VotingStaking.sol";

contract MintAndStake is Script {
    struct StakeInfo {
        address user;
        uint256 amount;
        uint256 durationYears;
    }

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        // Load deployment addresses
        string memory deploymentFile = vm.readFile("./deployment.json");
        address vvTokenAddress = vm.parseJsonAddress(deploymentFile, ".addresses.vvToken");
        address stakingAddress = vm.parseJsonAddress(deploymentFile, ".addresses.staking");

        VVToken vvToken = VVToken(vvTokenAddress);
        VotingStaking staking = VotingStaking(stakingAddress);

        // Get user addresses from environment or use deployer as default
        address user1 = vm.envOr("USER1_ADDRESS", deployer);
        address user2 = vm.envOr("USER2_ADDRESS", deployer);

        vm.startBroadcast(privateKey);

        // Mint tokens to users
        uint256 mintAmount = 10000 ether;
        vvToken.mint(user1, mintAmount);
        vvToken.mint(user2, mintAmount);
        console.log("Minted", mintAmount, "VV to", user1);
        console.log("Minted", mintAmount, "VV to", user2);

        // Approve and stake for user1
        vm.startPrank(user1);
        vvToken.approve(stakingAddress, 2000 ether);
        staking.stake(2000 ether, 3); // 3 years
        console.log("User1 staked 2000 VV for 3 years");
        vm.stopPrank();

        // Approve and stake for user2
        vm.startPrank(user2);
        vvToken.approve(stakingAddress, 1500 ether);
        staking.stake(1500 ether, 2); // 2 years
        console.log("User2 staked 1500 VV for 2 years");
        vm.stopPrank();

        // Save stake info
        StakeInfo[] memory stakes = new StakeInfo[](2);
        stakes[0] = StakeInfo(user1, 2000 ether, 3);
        stakes[1] = StakeInfo(user2, 1500 ether, 2);

        string memory output = vm.serializeAddress("stakes[0]", "user", stakes[0].user);
        output = vm.serializeUint(output, "amount", stakes[0].amount);
        output = vm.serializeUint(output, "durationYears", stakes[0].durationYears);
        output = vm.serializeAddress(output, "user", stakes[1].user);
        output = vm.serializeUint(output, "amount", stakes[1].amount);
        output = vm.serializeUint(output, "durationYears", stakes[1].durationYears);
        vm.writeJson(output, "./stakes_info.json");

        console.log("Stake info saved to stakes_info.json");

        vm.stopBroadcast();
    }
}