// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VotingCore.sol";
import "../src/VVToken.sol";
import "../src/VotingStaking.sol";

contract SetupTestVote is Script {
    struct VoteInfo {
        bytes32 votingId;
        uint256 deadline;
        uint256 threshold;
        string description;
    }

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        // Load deployment addresses
        string memory deploymentFile = vm.readFile("./deployment.json");
        address votingCoreAddress = vm.parseJsonAddress(deploymentFile, ".addresses.votingCore");
        address vvTokenAddress = vm.parseJsonAddress(deploymentFile, ".addresses.vvToken");
        address stakingAddress = vm.parseJsonAddress(deploymentFile, ".addresses.staking");

        VVToken vvToken = VVToken(vvTokenAddress);
        VotingStaking staking = VotingStaking(stakingAddress);
        VotingCore votingCore = VotingCore(votingCoreAddress);

        vm.startBroadcast(privateKey);

        // Create a test vote
        uint256 deadline = block.timestamp + 7 days;
        uint256 threshold = 5000;
        string memory description = "Should we increase protocol rewards by 20%?";

        bytes32 votingId = votingCore.createVoting(deadline, threshold, description);
        console.log("Voting created with ID:", vm.toString(votingId));
        console.log("Deadline:", deadline);
        console.log("Threshold:", threshold);
        console.log("Description:", description);

        // Save vote info
        VoteInfo memory voteInfo = VoteInfo({
            votingId: votingId,
            deadline: deadline,
            threshold: threshold,
            description: description
        });

        string memory output = vm.serializeBytes32("vote", "votingId", votingId);
        output = vm.serializeUint(output, "deadline", deadline);
        output = vm.serializeUint(output, "threshold", threshold);
        output = vm.serializeString(output, "description", description);
        vm.writeJson(output, "./vote_info.json");

        console.log("Vote info saved to vote_info.json");

        vm.stopBroadcast();
    }
}