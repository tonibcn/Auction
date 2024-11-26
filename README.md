# NFT Auction Platform

This project implements an NFT auction platform using smart contracts in Solidity. It includes three main components:

## Contracts

### 1. **NFTexample.sol**
- A basic ERC721 contract for creating and managing NFTs.
- Allows minting NFTs with a `mint` function that automatically increments the `tokenId`.

### 2. **NFTAuctionManager.sol**
- Serves as the auction manager for NFTs.
- **Key Functions**:
  - `createNFTAuction`: Creates a new auction for a specified NFT. Verifies NFT ownership, transfers it to the contract, and deploys an individual auction contract.
  - Manages registered auctions, including setting fees and withdrawing accumulated funds.
- **Events**:
  - `AuctionCreated`: Logs the creation of a new auction.
  - `DebugLog`: Aids in debugging NFT approvals and transfers.

### 3. **NFTAuction.sol**
- A dedicated contract for each auction.
- **Key Functions**:
  - `startAuction`: Starts the auction, specifying duration and time units.
  - `bid`: Allows users to place bids on the auction.
  - `endAuction`: Ends the auction, transfers the NFT to the winner, and handles fee distribution.
- **Events**:
  - `AuctionStarted`, `HighestBidIncreased`, `AuctionEnded`: Emit key auction lifecycle updates.
  - `NFTtransfertoAuction`, `NFTtransfertoWinner`: Document NFT transfers.

---

## Tests

### **NFTAuctionManager.t.sol**
- Automated tests using Foundry to ensure the correct functionality of the contracts.
- Verifies:
  - NFT ownership before and after creating an auction.
  - NFT transfers between participants and contracts.
  - Proper setup of auction contracts.

---

## How to Use
1. **Deploy `NFTexample.sol`:**
   - Generates NFTs that can be used in auctions.

2. **Deploy `NFTAuctionManager.sol`:**
   - Manages auction creation and fee configuration.

3. **Create an Auction:**
   - Call `createNFTAuction` to initiate an auction for a specific NFT.

4. **Interact with `NFTAuction.sol`:**
   - Participate in the auction by placing bids (`bid`) and finalizing it (`endAuction`) to transfer the NFT to the winner.

---

## Tools
- **Foundry**: For testing and deployment.
- **OpenZeppelin**: Standard contract libraries such as `ERC721` and `Ownable`.
