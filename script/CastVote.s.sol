// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VotingCore.sol";

contract CastVote is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address voter = vm.addr(privateKey);

        // Load addresses
        string memory deploymentFile = vm.readFile("./deployment.json");
        address votingCoreAddress = vm.parseJsonAddress(deploymentFile, ".addresses.votingCore");

        // Load vote info
        string memory voteFile = vm.readFile("./vote_info.json");
        bytes32 votingId = vm.parseJsonBytes32(voteFile, ".votingId");

        // Get vote choice from environment (true = yes, false = no)
        bool support = vm.envOr("VOTE_SUPPORT", true);

        VotingCore votingCore = VotingCore(votingCoreAddress);

        vm.startBroadcast(privateKey);

        // Check if vote is still active
        (uint256 deadline,,, uint256 yesVotes, uint256 noVotes, bool finalized,) = votingCore.getVoting(votingId);
        
        console.log("Voting ID:", vm.toString(votingId));
        console.log("Deadline:", deadline);
        console.log("Current time:", block.timestamp);
        console.log("Yes votes:", yesVotes);
        console.log("No votes:", noVotes);
        console.log("Finalized:", finalized);

        require(!finalized, "Vote already finalized");
        require(block.timestamp <= deadline, "Vote deadline passed");

        // Cast vote
        votingCore.castVote(votingId, support);
        console.log("Vote cast by:", voter);
        console.log("Support:", support ? "YES" : "NO");

        vm.stopBroadcast();
    }
}