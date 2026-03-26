# Vega Voting Protocol Architecture

## System Design

### Overview
The Vega Voting Protocol consists of four main contracts working together to provide a decentralized voting mechanism with time-weighted voting power.

### Contract Interactions

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Vega Voting Protocol                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐            │
│  │   VVToken    │     │VotingStaking │     │  VotingCore  │            │
│  │   (ERC20)    │◄────┤   (Staking)  │────►│  (Governance)│            │
│  └──────────────┘     └──────────────┘     └──────────────┘            │
│         ▲                    ▲                    │                     │
│         │                    │                    │                     │
│         │                    │                    ▼                     │
│         │                    │           ┌──────────────┐              │
│         │                    │           │VoteResultNFT│              │
│         │                    │           │   (ERC721)  │              │
│         │                    │           └──────────────┘              │
│         │                    │                                         │
│         └────────────────────┼─────────────────────────────────────────┘
│                              │                                         │
│                    ┌─────────▼─────────┐                               │
│                    │      Admin        │                               │
│                    │  (Ownable role)   │                               │
│                    └───────────────────┘                               │
└─────────────────────────────────────────────────────────────────────────┘
```

## Contract Details

### 1. VVToken (ERC20)
- Standard ERC20 implementation
- Mint/burn functions for admin
- Pausable for emergencies
- Used as governance token

### 2. VotingStaking
Manages user stakes and calculates voting power.

**Data Structures:**
```solidity
struct Stake {
    uint256 amount;           // Staked token amount
    uint256 startTime;        // When stake started
    uint256 initialDuration;  // Duration in seconds (1-4 years)
    bool withdrawn;           // Flag for withdrawn stakes
}
```

**Key Functions:**
- `stake(amount, durationYears)` - Create new stake
- `withdraw(stakeIndex)` - Withdraw after expiry
- `getVotingPower(user)` - Calculate current voting power

### 3. VotingCore
Main governance contract for vote creation and management.

**Data Structures:**
```solidity
struct Voting {
    bytes32 id;
    uint256 deadline;
    uint256 votingPowerThreshold;
    string description;
    uint256 yesVotes;
    uint256 noVotes;
    bool finalized;
    bool passed;
    mapping(address => bool) hasVoted;
    mapping(address => bool) voteChoice;
}
```

**Key Functions:**
- `createVoting(deadline, threshold, description)` - Admin only
- `castVote(votingId, support)` - Users vote
- `finalizeVote(votingId)` - Anyone can finalize

### 4. VoteResultNFT
ERC721 NFT storing vote results.

**Data Structures:**
```solidity
struct ResultMetadata {
    bytes32 votingId;
    string description;
    uint256 yesVotes;
    uint256 noVotes;
    uint256 threshold;
    bool passed;
    uint256 finalizedAt;
}
```

## Flow Diagrams

### Staking Flow
```
User → approve(VVToken) → stake() → VotingStaking
       ↓
   VVToken transfer
       ↓
   Stake created
```

### Voting Flow
```
Admin → createVoting() → VotingCore → Voting created
         ↓
User → castVote() → VotingCore
       ↓
   Check voting power from VotingStaking
       ↓
   Update yesVotes/noVotes
       ↓
   Auto-finalize if threshold met
```

### Finalization Flow
```
Anyone → finalizeVoting() → VotingCore
         ↓
   Check deadline passed
         ↓
   Calculate result
         ↓
   Mint VoteResultNFT
```

## Security Considerations

1. **Reentrancy Protection**: All external functions use `nonReentrant`
2. **Access Control**: `onlyOwner` for admin functions
3. **Pausable**: Emergency stop functionality
4. **Input Validation**: All user inputs validated
5. **Time Manipulation**: Uses `block.timestamp` but no critical reliance

## Gas Optimization

- Storage efficient structures
- Minimal storage writes
- Optimized loops with early breaks
- Using `mapping` for direct access

