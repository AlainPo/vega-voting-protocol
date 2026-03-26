// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VotingCore.sol";
import "../src/VoteResultNFT.sol";

contract FinalizeVote is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address caller = vm.addr(privateKey);

        // Load addresses
        string memory deploymentFile = vm.readFile("./deployment.json");
        address votingCoreAddress = vm.parseJsonAddress(deploymentFile, ".addresses.votingCore");
        address resultNFTAddress = vm.parseJsonAddress(deploymentFile, ".addresses.resultNFT");

        // Load vote info
        string memory voteFile = vm.readFile("./vote_info.json");
        bytes32 votingId = vm.parseJsonBytes32(voteFile, ".votingId");

        VotingCore votingCore = VotingCore(votingCoreAddress);
        VoteResultNFT resultNFT = VoteResultNFT(resultNFTAddress);

        vm.startBroadcast(privateKey);

        // Get current vote state
        (uint256 deadline,,, uint256 yesVotes, uint256 noVotes, bool finalized, bool passed) = votingCore.getVoting(votingId);
        
        console.log("Voting ID:", vm.toString(votingId));
        console.log("Yes votes:", yesVotes);
        console.log("No votes:", noVotes);
        console.log("Finalized:", finalized);

        if (!finalized) {
            // Check if deadline passed or threshold met
            if (block.timestamp > deadline) {
                console.log("Deadline passed, finalizing...");
                votingCore.finalizeVoting(votingId);
                console.log("Vote finalized by:", caller);
            } else if (yesVotes >= (uint256(vm.envOr("THRESHOLD", 0)))) {
                console.log("Threshold met, finalizing...");
                votingCore.finalizeVoting(votingId);
                console.log("Vote finalized by:", caller);
            } else {
                console.log("Cannot finalize: deadline not passed and threshold not met");
                console.log("Current yes votes:", yesVotes);
                console.log("Threshold required:", vm.envOr("THRESHOLD", 0));
                revert("Cannot finalize vote");
            }
        } else {
            console.log("Vote already finalized");
        }

        // Get NFT info if minted
        uint256 tokenId = resultNFT.votingIdToTokenId(votingId);
        if (tokenId != 0) {
            VoteResultNFT.ResultMetadata memory metadata = resultNFT.results(tokenId);
            console.log("NFT minted with token ID:", tokenId);
            console.log("Result passed:", metadata.passed);
            console.log("Finalized at:", metadata.finalizedAt);
        }

        vm.stopBroadcast();
    }
}