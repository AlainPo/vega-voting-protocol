// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./VVToken.sol";

contract VotingStaking is Ownable, ReentrancyGuard, Pausable {
    VVToken public immutable vvToken;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 initialDuration; // in seconds
        bool withdrawn;
    }

    // 1 year in seconds = 365 days
    uint256 public constant YEAR_IN_SECONDS = 365 days;

    mapping(address => Stake[]) public stakes;

    event Staked(address indexed user, uint256 stakeIndex, uint256 amount, uint256 duration);
    event Withdrawn(address indexed user, uint256 stakeIndex, uint256 amount);

    constructor(address _vvToken, address initialOwner) Ownable(initialOwner) {
        vvToken = VVToken(_vvToken);
    }

    /**
     * @dev Stake tokens for a specified duration (1-4 years)
     * @param amount Amount of VV tokens to stake
     * @param initialDurationYears Duration in years (1 to 4)
     */
    function stake(uint256 amount, uint256 initialDurationYears) external nonReentrant whenNotPaused {
        require(initialDurationYears >= 1 && initialDurationYears <= 4, "Duration must be between 1 and 4 years");
        require(amount > 0, "Amount must be greater than 0");

        uint256 durationSeconds = initialDurationYears * YEAR_IN_SECONDS;

        // Transfer tokens from user to this contract
        vvToken.transferFrom(msg.sender, address(this), amount);

        stakes[msg.sender].push(Stake({
            amount: amount,
            startTime: block.timestamp,
            initialDuration: durationSeconds,
            withdrawn: false
        }));

        emit Staked(msg.sender, stakes[msg.sender].length - 1, amount, durationSeconds);
    }

    /**
     * @dev Withdraw a specific stake after it has expired
     * @param stakeIndex Index of the stake in the user's stakes array
     */
    function withdraw(uint256 stakeIndex) external nonReentrant whenNotPaused {
        Stake storage userStake = stakes[msg.sender][stakeIndex];
        require(!userStake.withdrawn, "Stake already withdrawn");
        require(_getRemainingDuration(userStake) == 0, "Stake still active");

        uint256 amount = userStake.amount;
        userStake.withdrawn = true;

        vvToken.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, stakeIndex, amount);
    }

    /**
     * @dev Get the remaining duration of a stake in seconds
     */
    function getRemainingDuration(address user, uint256 stakeIndex) public view returns (uint256) {
        Stake storage userStake = stakes[user][stakeIndex];
        if (userStake.withdrawn) return 0;
        return _getRemainingDuration(userStake);
    }

    /**
     * @dev Get the current voting power of a user
     * VP = sum(D_remain^2 * amount) / (YEAR_IN_SECONDS^2)
     * This normalizes the value to be in "person-years^2" units
     */
    function getVotingPower(address user) public view returns (uint256) {
        Stake[] storage userStakes = stakes[user];
        uint256 totalVP = 0;

        for (uint256 i = 0; i < userStakes.length; i++) {
            Stake storage userStake = userStakes[i];
            if (userStake.withdrawn) continue;

            uint256 remaining = _getRemainingDuration(userStake);
            if (remaining == 0) continue;

            // Calculate: (remaining^2 * amount) / YEAR_IN_SECONDS^2
            // Using muldiv to avoid overflow
            uint256 remainingSquared = remaining * remaining;
            uint256 numerator = remainingSquared * userStake.amount;
            totalVP += numerator / (YEAR_IN_SECONDS * YEAR_IN_SECONDS);
        }

        return totalVP;
    }

    /**
     * @dev Internal function to get remaining duration
     */
    function _getRemainingDuration(Stake memory userStake) internal view returns (uint256) {
        uint256 expiry = userStake.startTime + userStake.initialDuration;
        if (block.timestamp >= expiry) return 0;
        return expiry - block.timestamp;
    }

    /**
     * @dev Get total staked amount for a user
     */
    function getTotalStaked(address user) public view returns (uint256) {
        Stake[] storage userStakes = stakes[user];
        uint256 total = 0;
        for (uint256 i = 0; i < userStakes.length; i++) {
            if (!userStakes[i].withdrawn) {
                total += userStakes[i].amount;
            }
        }
        return total;
    }

    /**
     * @dev Get number of stakes for a user
     */
    function getStakeCount(address user) external view returns (uint256) {
        return stakes[user].length;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}