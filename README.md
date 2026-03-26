# Vega Voting Protocol

[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-1.0-orange)](https://book.getfoundry.sh/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## 📋 Overview

Vega Voting Protocol is a decentralized voting system where voting power is determined by the amount and duration of staked VV tokens. The protocol features:

- **Time-weighted voting power**: `VP = Σ (remaining_duration² × amount)`
- **ERC20 token**: VV (VegaVoting)
- **ERC721 NFTs**: Result certificates for finalized votes
- **Auto-finalization**: When threshold is met or deadline passes
- **Admin controls**: Only owner can create votes

📊 **Full deployment details and transaction proofs available in [DEPLOYMENT.md](DEPLOYMENT.md)**

## 🏗️ Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   VVToken    │     │VotingStaking │     │  VotingCore  │
│   (ERC20)    │◄────┤   (Staking)  │────►│ (Governance) │
└──────────────┘     └──────────────┘     └──────────────┘
       ▲                    ▲                    │
       │                    │                    ▼
       │                    │           ┌──────────────┐
       │                    │           │VoteResultNFT│
       │                    │           │   (ERC721)   │
       │                    │           └──────────────┘
       └────────────────────┼───────────────────────────┘
                            │
                    ┌───────▼───────┐
                    │     Admin     │
                    │  (Ownable)    │
                    └───────────────┘
```

## 📦 Contracts

| Contract | Description |
|----------|-------------|
| `VVToken` | ERC20 token for staking and voting |
| `VotingStaking` | Manages stakes and calculates voting power |
| `VotingCore` | Main governance contract for creating and managing votes |
| `VoteResultNFT` | ERC721 NFT storing finalized vote results |

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js (for some scripts)

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/vega-voting-protocol.git
cd vega-voting-protocol

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test -vvv
```

### Deployment to Sepolia

```bash
# Set up environment variables
cp .env.example .env
# Edit .env with your private keys and API keys

# Deploy all contracts
forge script script/DeployVegaVoting.s.sol \
    --rpc-url sepolia \
    --private-key $ADMIN_PRIVATE_KEY \
    --broadcast \
    --verify
```

### Test Vote Flow

```bash
# Full automated setup (deploy + stake + create vote)
forge script script/SetupFullEnvironment.s.sol \
    --rpc-url sepolia \
    --private-key $ADMIN_PRIVATE_KEY \
    --broadcast

# Cast vote as voter 1
forge script script/CastVote.s.sol \
    --rpc-url sepolia \
    --private-key $VOTER1_PRIVATE_KEY \
    --broadcast \
    --sig "run()" \
    -vvvv

# Finalize vote (after deadline or when threshold met)
forge script script/FinalizeVote.s.sol \
    --rpc-url sepolia \
    --private-key $ADMIN_PRIVATE_KEY \
    --broadcast
```

## 🧪 Testing

```bash
# Run all tests
forge test

# Run with gas report
forge test --gas-report

# Run specific test
forge test --match-test test_EarlyFinalizationWhenThresholdMet -vvv
```

## 📊 Voting Power Calculation

Voting power is calculated as:

```
VP = Σ (D_remain² × amount)
```

Where:
- `D_remain` = remaining stake duration in years
- `amount` = staked VV tokens

Example: Staking 1000 VV for 3 years gives `3² × 1000 = 9000` voting power.
