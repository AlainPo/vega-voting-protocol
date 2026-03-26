# Deployment Guide

## Prerequisites

### 1. Install Foundry
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Get Sepolia ETH
- [Alchemy Faucet](https://sepoliafaucet.com/)
- [Infura Faucet](https://www.infura.io/faucet/sepolia)

### 3. Create API Keys
- [Alchemy](https://dashboard.alchemy.com/) - For RPC endpoint
- [Etherscan](https://etherscan.io/register) - For contract verification

## Deployment Steps

### Step 1: Configure Environment
```bash
cp .env.example .env
# Edit .env with your private keys
```

### Step 2: Deploy Contracts
```bash
forge script script/DeployVegaVoting.s.sol \
    --rpc-url sepolia \
    --private-key $ADMIN_PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

**Expected Output:**
```
VVToken deployed at: 0x...
VotingStaking deployed at: 0x...
VoteResultNFT deployed at: 0x...
VotingCore deployed at: 0x...
Transferred VoteResultNFT ownership to VotingCore
Minted 10000 VV to deployer
Deployment addresses saved to deployment.json
```

### Step 3: Verify Contract Addresses
```bash
cat deployment.json
```

### Step 4: Mint Tokens for Voters
```bash
# Mint 10,000 VV for voter 1
cast send $VV_TOKEN "mint(address,uint256)" $VOTER1_ADDRESS 10000000000000000000000 \
    --private-key $ADMIN_PRIVATE_KEY --rpc-url sepolia

# Mint 10,000 VV for voter 2
cast send $VV_TOKEN "mint(address,uint256)" $VOTER2_ADDRESS 10000000000000000000000 \
    --private-key $ADMIN_PRIVATE_KEY --rpc-url sepolia
```

### Step 5: Stake Tokens
```bash
# Approve tokens
cast send $VV_TOKEN "approve(address,uint256)" $STAKING 2000000000000000000000 \
    --private-key $VOTER1_PRIVATE_KEY --rpc-url sepolia

# Stake for 3 years
cast send $STAKING "stake(uint256,uint256)" 2000000000000000000000 3 \
    --private-key $VOTER1_PRIVATE_KEY --rpc-url sepolia
```

### Step 6: Create Vote
```bash
DEADLINE=$(($(date +%s) + 604800))  # 7 days
cast send $VOTING_CORE "createVoting(uint256,uint256,string)" $DEADLINE 5000 "Should we increase rewards?" \
    --private-key $ADMIN_PRIVATE_KEY --rpc-url sepolia
```

### Step 7: Cast Votes
```bash
# Voter 1 votes YES
cast send $VOTING_CORE "castVote(bytes32,bool)" $VOTING_ID true \
    --private-key $VOTER1_PRIVATE_KEY --rpc-url sepolia

# Voter 2 votes NO
cast send $VOTING_CORE "castVote(bytes32,bool)" $VOTING_ID false \
    --private-key $VOTER2_PRIVATE_KEY --rpc-url sepolia
```

### Step 8: Finalize Vote
```bash
cast send $VOTING_CORE "finalizeVoting(bytes32)" $VOTING_ID \
    --private-key $ADMIN_PRIVATE_KEY --rpc-url sepolia
```

### Step 9: View Results
```bash
# Get voting info
cast call $VOTING_CORE "getVoting(bytes32)" $VOTING_ID --rpc-url sepolia

# Get NFT
TOKEN_ID=$(cast call $RESULT_NFT "votingIdToTokenId(bytes32)" $VOTING_ID --rpc-url sepolia)
cast call $RESULT_NFT "ownerOf(uint256)" $TOKEN_ID --rpc-url sepolia
```

## Troubleshooting

### Common Issues

1. **Nonce too low**
   ```bash
   cast send --nonce $(cast nonce --rpc-url sepolia $ADMIN_ADDRESS) ...
   ```

2. **Insufficient funds**
   - Check balance: `cast balance $ADMIN_ADDRESS --rpc-url sepolia`
   - Get Sepolia ETH from faucet

3. **Gas estimation failed**
   - Increase gas limit: `--gas-limit 500000`

## Verification on Etherscan

After deployment, contracts can be verified:

```bash
forge verify-contract $VV_TOKEN src/VVToken.sol:VVToken \
    --chain-id 11155111 \
    --constructor-args $(cast abi-encode "constructor(address)" $ADMIN_ADDRESS) \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

## Deployed Addresses (Example)

| Contract | Address |
|----------|---------|
| VVToken | 0x... |
| VotingStaking | 0x... |
| VoteResultNFT | 0x... |
| VotingCore | 0x... |

## Links

- [Sepolia Etherscan](https://sepolia.etherscan.io/)
- [Alchemy Dashboard](https://dashboard.alchemy.com/)