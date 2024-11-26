// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

    import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

    contract NFTexample is ERC721 {
        uint256 public tokenCounter;

        constructor() ERC721("MockNFT", "MNFT") {
            tokenCounter = 0;
        }

        function mint() public returns (uint256) {
            uint256 newTokenId = tokenCounter;
            _safeMint(msg.sender, newTokenId);
            tokenCounter++;
            return newTokenId;
        }
    }
