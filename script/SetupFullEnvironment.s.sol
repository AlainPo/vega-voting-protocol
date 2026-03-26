// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "./DeployVegaVoting.s.sol";
import "./MintAndStake.s.sol";
import "./SetupTestVote.s.sol";

contract SetupFullEnvironment is Script {
    function run() external {
        console.log("=== Starting full environment setup ===");
        
        // Step 1: Deploy contracts
        console.log("\n[1/3] Deploying contracts...");
        DeployVegaVoting deployScript = new DeployVegaVoting();
        deployScript.run();
        
        // Step 2: Mint and stake tokens
        console.log("\n[2/3] Minting and staking tokens...");
        MintAndStake stakeScript = new MintAndStake();
        stakeScript.run();
        
        // Step 3: Create test vote
        console.log("\n[3/3] Creating test vote...");
        SetupTestVote voteScript = new SetupTestVote();
        voteScript.run();
        
        console.log("\n=== Full environment setup complete ===");
        console.log("Next steps:");
        console.log("1. Run: forge script script/CastVote.s.sol --rpc-url sepolia --broadcast");
        console.log("2. Run: forge script script/FinalizeVote.s.sol --rpc-url sepolia --broadcast");
    }
}