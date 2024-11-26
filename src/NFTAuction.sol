// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTAuction is Ownable, IERC721Receiver {
    IERC721 public nftContract;
    uint256 public nftTokenId;

    // Estado adicional
    address public nftOwner; // Propietario original del NFT

    address public feeAddress;
    uint256 public feePercentage; // example; 50 is 5% of the highest auction

    address public ownerAddress;
    uint256 public startTime;
    uint256 public endTime;
    bool public ended;
    address public highestBidder;
    uint256 public highestBid;
    address public winner;
    mapping(address => uint256) public bids;

    // Custom Errors
    error AuctionAlreadyEnded();
    error AuctionNotYetEnded();
    error BidNotHighEnough(uint256 highestBid);
    error AuctionAlreadyStarted();  
    error NoBidToWithdraw();
    error TransferFailed();

    // Events
    event AuctionStarted(uint256 startTime, uint256 endTime);
    event HighestBidIncreased(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event NFTtransfertoAuction(address from, address to, uint256 nftid);
    event NFTtransfertoWinner(address from, address to, uint256 nftid);
    // Declaración del evento DebugLog
    event DebugLog(string message, bool isApproved, uint256 tokenId);

    address public auctionManager;

    constructor(
        address _ownerAddress,
        address _feeAddress,
        uint256 _feePercentage,
        address _nftContractAddress,
        uint256 _nftTokenId
    ) Ownable(_ownerAddress) {
        ownerAddress = _ownerAddress;
        feeAddress = _feeAddress;
        feePercentage = _feePercentage;
        nftContract = IERC721(_nftContractAddress);
        nftTokenId = _nftTokenId;
        nftOwner = _ownerAddress; // Almacena el propietario original del NFT
        auctionManager = msg.sender;
    }

    enum TimeUnit { Minutes, Hours, Days }

    modifier onlyOwnerOrManager() {
        require(msg.sender == owner() || msg.sender == auctionManager, "OwnableUnauthorizedAccount");
        _;
        emit DebugLog("Auction started by:", msg.sender == auctionManager, 0); // Emitir evento para confirmar quién inicia la subasta
    }

function startAuction(uint256 _biddingTime, TimeUnit _unit) public onlyOwnerOrManager {
    if (startTime != 0) {
        revert AuctionAlreadyStarted();
    }
    startTime = block.timestamp;

    if (_unit == TimeUnit.Days) {
        endTime = startTime + (_biddingTime * 1 days);
    } else if (_unit == TimeUnit.Hours) {
        endTime = startTime + (_biddingTime * 1 hours);
    } else if (_unit == TimeUnit.Minutes) {
        endTime = startTime + (_biddingTime * 1 minutes);
    }

    // Confirmar que el contrato ya es propietario del NFT
    require(nftContract.ownerOf(nftTokenId) == address(this), "NFTAuction does not own the NFT");

    emit AuctionStarted(startTime, endTime);
    }


function bid() external payable {
    // Requerir que la subasta no haya terminado
    if (block.timestamp > endTime) {
        revert AuctionAlreadyEnded();
    }

    // Requerir que la oferta sea mayor que la oferta más alta actual
    if (msg.value <= highestBid) {
        revert BidNotHighEnough(highestBid);
    }

    // Almacenar los datos del postor anterior y su oferta
    address previousBidder = highestBidder;
    uint256 previousBid = highestBid;

    // Actualizar el estado primero (EFFECTS)
    highestBid = msg.value;
    highestBidder = msg.sender;
    bids[msg.sender] = msg.value;

    // Interacciones externas (INTERACTIONS)
    if (previousBidder != address(0)) {
        (bool success, ) = payable(previousBidder).call{value: previousBid}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    // Emitir el evento
    emit HighestBidIncreased(msg.sender, msg.value);
    }

    function endAuction() external onlyOwner {
        if (ended) {
            revert AuctionAlreadyEnded();
        }
        if (block.timestamp <= endTime) {
            revert AuctionNotYetEnded();
        }
        ended = true;

        uint256 fee = calculateFee(highestBid);
        uint256 amount = highestBid - fee;

        transferFee(fee);
        transferToOwner(amount);

        nftContract.safeTransferFrom(address(this), highestBidder, nftTokenId);

        emit AuctionEnded(highestBidder, highestBid);
        emit NFTtransfertoWinner(address(this), highestBidder, nftTokenId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function transferFee(uint256 fee) internal onlyOwner {
        if (ended) {
            revert AuctionNotYetEnded();
        }

        (bool success, ) = payable(address(feeAddress)).call{value: fee}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    function transferToOwner(uint256 amount) internal {
        (bool success, ) = payable(owner()).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    function calculateFee(uint256 amount) internal view returns (uint256) {
        return ((amount * feePercentage) / 1000);
    }
}
