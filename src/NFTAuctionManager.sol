// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {NFTAuction} from "src/NFTAuction.sol";

contract NFTAuctionManager is Ownable {
    NFTAuction[] public nftAuctions;
    uint256 public defaultFeePercentage = 50; // Default fee percentage (e.g., 5%)

    error InvalidAuctionIndex();
    error NoBalance();  
    error TransferFailed();
    error ApprovalRequired();

    // Enum para TimeUnit
    enum TimeUnit {
        Seconds,
        Minutes,
        Hours,
        Days
    }

    // Evento para registrar la creación de subastas
    event AuctionCreated(address auctionAddress);
    // Evento para depuración detallada
    event DebugLog(string message, bool isApproved, uint256 tokenId);
    

    // Constructor que llama al constructor de Ownable
    constructor() Ownable(msg.sender) {}

    function createNFTAuction(
    address _nftContractAddress,
    uint256 _nftTokenId,
    uint256 _biddingTime,
    TimeUnit _unit
    ) public {

    // Obtener el propietario actual del NFT
    address nftOwner = IERC721(_nftContractAddress).ownerOf(_nftTokenId);

    // Requerir que el creador de la subasta sea el propietario del NFT o que el contrato ya lo posea
    require(
        nftOwner == msg.sender || nftOwner == address(this),
        "Caller is not the owner of the NFT"
    );

    // Si el NFT aún no está en el contrato, transferirlo
    if (nftOwner != address(this)) {
        // Verificar que el contrato está aprobado para manejar el NFT
        require(
            IERC721(_nftContractAddress).getApproved(_nftTokenId) == address(this) ||
            IERC721(_nftContractAddress).isApprovedForAll(nftOwner, address(this)),
            "NFTAuctionManager is not approved to manage this NFT"
        );

        // Transferir el NFT al contrato
        IERC721(_nftContractAddress).safeTransferFrom(nftOwner, address(this), _nftTokenId);
    }

    // Confirmar que el contrato ahora es propietario del NFT
    require(
        IERC721(_nftContractAddress).ownerOf(_nftTokenId) == address(this),
        "NFTAuctionManager did not receive the NFT"
    );

    // Crear el contrato de subasta
    NFTAuction newAuctionContract = new NFTAuction(
        msg.sender,
        address(this),
        defaultFeePercentage,
        _nftContractAddress,
        _nftTokenId
    );

    // Transferir el NFT al contrato de subasta
    IERC721(_nftContractAddress).safeTransferFrom(address(this), address(newAuctionContract), _nftTokenId);

    // Confirmar que el contrato de subasta ahora es propietario del NFT
    require(
        IERC721(_nftContractAddress).ownerOf(_nftTokenId) == address(newAuctionContract),
        "NFTAuction contract did not receive the NFT"
    );

    // Iniciar la subasta
    newAuctionContract.startAuction(_biddingTime, NFTAuction.TimeUnit(uint8(_unit)));

    // Registrar la subasta
    nftAuctions.push(newAuctionContract);

    // Emitir evento de creación
    emit AuctionCreated(address(newAuctionContract));
}


    // Función para obtener el número de subastas
    function getAuctionsCount() public view returns (uint256) {
        return nftAuctions.length;
    }

    // Función para obtener una subasta por índice
    function getAuction(uint256 _index) public view returns (address) {
        if (_index >= nftAuctions.length) {
            revert InvalidAuctionIndex();
        }
        return address(nftAuctions[_index]);
    }

    // Función para establecer el porcentaje de comisión
    function setFeePercentage(uint256 _feePercentage) public onlyOwner {
        defaultFeePercentage = _feePercentage;
    }

    // Función para retirar el saldo del contrato
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert NoBalance();
        }
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    // Función para recibir NFTs (ERC721) en el contrato
    function onERC721Received(
        address, // operator
        address from,
        uint256 tokenId,
        bytes calldata // data
    ) external returns (bytes4) {
        emit DebugLog("NFT received", true, tokenId);
        return this.onERC721Received.selector; // Esta es la función estándar para recibir tokens ERC721
    }

    // Función para recibir Ether
    receive() external payable {}
}
