// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract VoteResultNFT is ERC721, Ownable {
    using Strings for uint256;

    struct ResultMetadata {
        bytes32 votingId;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 threshold;
        bool passed;
        uint256 finalizedAt;
    }

    uint256 private _nextTokenId;
    mapping(uint256 => ResultMetadata) public results;
    mapping(bytes32 => uint256) public votingIdToTokenId;

    event ResultNFTMinted(uint256 indexed tokenId, bytes32 indexed votingId, bool passed);

    constructor(address initialOwner) ERC721("VoteResult", "VRT") Ownable(initialOwner) {}

    /**
     * @dev Mint an NFT for a completed vote. Only callable by owner (VotingCore)
     */
    function mint(address to, ResultMetadata memory metadata) external onlyOwner returns (uint256) {
        require(votingIdToTokenId[metadata.votingId] == 0, "Vote already has NFT");

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        results[tokenId] = metadata;
        votingIdToTokenId[metadata.votingId] = tokenId;

        emit ResultNFTMinted(tokenId, metadata.votingId, metadata.passed);
        return tokenId;
    }

    /**
     * @dev Get token URI for metadata
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "ERC721Metadata: URI query for nonexistent token");

        ResultMetadata memory metadata = results[tokenId];
        return string(abi.encodePacked(
            "data:application/json;base64,",
            _base64(abi.encodePacked(
                '{"name":"Vote Result #', tokenId.toString(),
                '","description":"', metadata.description,
                '","votingId":"', bytes32ToString(metadata.votingId),
                '","yesVotes":', metadata.yesVotes.toString(),
                ',"noVotes":', metadata.noVotes.toString(),
                ',"threshold":', metadata.threshold.toString(),
                ',"passed":', metadata.passed ? "true" : "false",
                ',"finalizedAt":', metadata.finalizedAt.toString(),
                '}'
            ))
        ));
    }

    /**
     * @dev Helper to convert bytes32 to string
     */
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (uint8 j = 0; j < i; j++) {
            bytesArray[j] = _bytes32[j];
        }
        return string(bytesArray);
    }

    /**
     * @dev Base64 encoding helper
     */
    function _base64(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        uint256 len = data.length;
        string memory result = new string(4 * ((len + 2) / 3));
        bytes memory resultBytes = bytes(result);
        uint256 resultIndex = 0;
        for (uint256 i = 0; i < len; i += 3) {
            uint256 triplet = (uint256(uint8(data[i])) << 16);
            if (i + 1 < len) triplet |= (uint256(uint8(data[i + 1])) << 8);
            if (i + 2 < len) triplet |= uint256(uint8(data[i + 2]));

            resultBytes[resultIndex++] = alphabet[uint8(triplet >> 18)];
            resultBytes[resultIndex++] = alphabet[uint8((triplet >> 12) & 0x3F)];
            resultBytes[resultIndex++] = alphabet[uint8((triplet >> 6) & 0x3F)];
            resultBytes[resultIndex++] = alphabet[uint8(triplet & 0x3F)];
        }
        // Handle padding
        if (len % 3 == 1) {
            resultBytes[resultIndex - 2] = '=';
            resultBytes[resultIndex - 1] = '=';
        } else if (len % 3 == 2) {
            resultBytes[resultIndex - 1] = '=';
        }
        return result;
    }
}