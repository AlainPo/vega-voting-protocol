// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VVToken.sol";
import "../src/VotingStaking.sol";
import "../src/VoteResultNFT.sol";
import "../src/VotingCore.sol";

contract DeployVegaVoting is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy VVToken
        VVToken vvToken = new VVToken(deployer);
        console.log("VVToken deployed at:", address(vvToken));

        // Deploy VotingStaking
        VotingStaking staking = new VotingStaking(address(vvToken), deployer);
        console.log("VotingStaking deployed at:", address(staking));

        // Deploy VoteResultNFT
        VoteResultNFT resultNFT = new VoteResultNFT(deployer);
        console.log("VoteResultNFT deployed at:", address(resultNFT));

        // Deploy VotingCore
        VotingCore votingCore = new VotingCore(address(staking), address(resultNFT), deployer);
        console.log("VotingCore deployed at:", address(votingCore));

        // Transfer NFT ownership to VotingCore
        resultNFT.transferOwnership(address(votingCore));
        console.log("Transferred VoteResultNFT ownership to VotingCore");

        // Mint some test tokens for users
        vvToken.mint(deployer, 10000 ether);
        console.log("Minted 10000 VV to deployer");

        vm.stopBroadcast();
    }
}