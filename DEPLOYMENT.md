# Sepolia Testnet Deployment Report

## Contract Addresses
| Contract | Address | Etherscan |
|----------|---------|-----------|
| VVToken | `0x76D122b5fB760E59c3Ba8D6781414a19a48B4401` | [View](https://sepolia.etherscan.io/address/0x76D122b5fB760E59c3Ba8D6781414a19a48B4401) |
| VotingStaking | `0x1094eF6626ea72c147b0658163E51a42DCC38eeD` | [View](https://sepolia.etherscan.io/address/0x1094eF6626ea72c147b0658163E51a42DCC38eeD) |
| VoteResultNFT | `0xB48E6fcA591204C17D56dDd77fB3cBdab1f3882D` | [View](https://sepolia.etherscan.io/address/0xB48E6fcA591204C17D56dDd77fB3cBdab1f3882D) |
| VotingCore | `0x8BD8F5dc818844CBF49AE7320a40754bd6f5456B` | [View](https://sepolia.etherscan.io/address/0x8BD8F5dc818844CBF49AE7320a40754bd6f5456B) |

## Voting Demonstration

### Vote Created
- **Voting ID**: `0xbde566c623e90ba5ec5e6f3536268d7e43fdf5bd23c6d3d014f9788902f0ebe8`
- **Description**: "Should we increase protocol rewards by 20%?"
- **Threshold**: 5,000 voting power
- **Transaction**: [0xa1e365949dc577c6ccc992044a60d1fd02db23d1fb0002cbf1c6fff1dad1f60f](https://sepolia.etherscan.io/tx/0xa1e365949dc577c6ccc992044a60d1fd02db23d1fb0002cbf1c6fff1dad1f60f)

### Voter 1
- **Address**: `0xF4A968F331fCc90846Da1e4606E04a7b391E6b5A`
- **Stake**: 2,000 VV for 3 years → 18,000 voting power
- **Vote**: YES
- **Transaction**: [0x436a93a0320e894a71510caff9d6cef1f31f767bca17ed75011d0a3c685a1332](https://sepolia.etherscan.io/tx/0x436a93a0320e894a71510caff9d6cef1f31f767bca17ed75011d0a3c685a1332)

### Voter 2 (not needed - auto-finalized)
- **Address**: `0xE14668D44C0d375fFAADEbaaA6361cF3AA59bAB0`
- **Stake**: 1,500 VV for 2 years → 6,000 voting power

### Vote Result
- **Yes Votes**: 18,000
- **No Votes**: 0
- **Threshold**: 5,000
- **Result**: ✅ **PASSED**
- **Finalization**: Auto-finalized when threshold met

### Result NFT
- **NFT Contract**: `0xB48E6fcA591204C17D56dDd77fB3cBdab1f3882D`
- **Token ID**: `1`
- **View**: [Etherscan](https://sepolia.etherscan.io/token/0xB48E6fcA591204C17D56dDd77fB3cBdab1f3882D?a=1)

## All Transactions Summary

| Action | Transaction Hash |
|--------|------------------|
| Deploy VVToken | [0x61efe835...](https://sepolia.etherscan.io/tx/0x61efe835373fa1a5b439645900c5558dca71d8c2b12208251a43ee96c4a4c889) |
| Deploy VotingStaking | [0x47ed098e...](https://sepolia.etherscan.io/tx/0x47ed098e84dcf1e842dfe2793b2648479c41c544ac5c4c53a2e7dbdce48c3e06) |
| Deploy VoteResultNFT | [0x6053a251...](https://sepolia.etherscan.io/tx/0x6053a2514e756d8ba049956ff174a437a1b2952eb286b15c43cd245d2a741430) |
| Deploy VotingCore | [0x225b3729...](https://sepolia.etherscan.io/tx/0x225b3729acc67ce873e778f407d47960618bacf042990c0e4714fcf96efa54ff) |
| Mint Voter1 | [0xacee3774...](https://sepolia.etherscan.io/tx/0xacee3774e8af4531f68f0deee63b509fb9683948d39e28cbf20c96f97c23b08f) |
| Mint Voter2 | [0xed77566f...](https://sepolia.etherscan.io/tx/0xed77566fa4826642afb52b2baef85ec1f58aeee8e52a0e3ff54bffe928a45799) |
| Stake Voter1 | [0xa5c2136f...](https://sepolia.etherscan.io/tx/0xa5c2136fa8a7b09c59388acf3443d3ad39b8efd10d26af98cd6d3d4887b13c33) |
| Stake Voter2 | [0xfbb36493...](https://sepolia.etherscan.io/tx/0xfbb36493a42853de5f0af911ee92bc6f70c0fe84dfacb8aa2ea07e3561989a18) |
| Create Vote | [0xa1e36594...](https://sepolia.etherscan.io/tx/0xa1e365949dc577c6ccc992044a60d1fd02db23d1fb0002cbf1c6fff1dad1f60f) |
| Cast Vote (YES) | [0x436a93a0...](https://sepolia.etherscan.io/tx/0x436a93a0320e894a71510caff9d6cef1f31f767bca17ed75011d0a3c685a1332) |

## Verification
All contracts are verified on Etherscan and can be viewed at the links above.