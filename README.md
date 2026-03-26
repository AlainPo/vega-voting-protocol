# Vega Voting Protocol

[![Solidity](https://img.shields.io/badge/Solidity-0.8.24-blue)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-1.0-orange)](https://book.getfoundry.sh/)

## 📋 Overview

Vega Voting Protocol is a decentralized voting system where voting power is determined by the amount and duration of staked VV tokens. The protocol features:

- **Time-weighted voting power**: `VP = Σ (remaining_duration² × amount)`
- **Staking periods**: 1-4 years
- **ERC20 token**: VV (VegaVoting)
- **ERC721 NFTs**: Result certificates for finalized votes
- **Auto-finalization**: When threshold is met or deadline passes
- **Admin controls**: Only owner can create votes

## 🔗 Sepolia Deployment

| Contract | Address |
|----------|---------|
| VVToken | `0x76D122b5fB760E59c3Ba8D6781414a19a48B4401` |
| VotingStaking | `0x1094eF6626ea72c147b0658163E51a42DCC38eeD` |
| VoteResultNFT | `0xB48E6fcA591204C17D56dDd77fB3cBdab1f3882D` |
| VotingCore | `0x8BD8F5dc818844CBF49AE7320a40754bd6f5456B` |

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
- Sepolia ETH for deployment

### Installation

```bash
# Clone the repository
git clone https://github.com/AlainPo/vega-voting-protocol.git
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
    -vvvv
```

## 📊 Voting Power Calculation

Voting power is calculated as:

```
VP = Σ (D_remain² × amount)
```

Where:
- `D_remain` = remaining stake duration in years
- `amount` = staked VV tokens

Example: Staking 2000 VV for 3 years gives `3² × 2000 = 18,000` voting power.

