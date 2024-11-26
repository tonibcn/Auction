// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {NFTexample} from "../src/NFTexample.sol";
import {NFTAuctionManager} from "../src/NFTAuctionManager.sol";
import {NFTAuction} from "../src/NFTAuction.sol";

contract NFTAuctionManagerTest is Test {
    NFTexample nftExample;
    NFTAuctionManager nftAuctionManager;

    address deployer = address(1);

    function setUp() public {
        // Desplegar contratos
        nftExample = new NFTexample();
        nftAuctionManager = new NFTAuctionManager();

        // Mintear un NFT desde el deployer
        vm.startPrank(deployer);
        uint256 tokenId = nftExample.mint();
        vm.stopPrank();

        // Verificar que el deployer es el propietario del NFT
        assertEq(nftExample.ownerOf(tokenId), deployer, "Deployer no es el propietario inicial del NFT");

        // Aprobar a NFTAuctionManager para gestionar el NFT
        vm.startPrank(deployer);
        nftExample.approve(address(nftAuctionManager), tokenId);
        vm.stopPrank();
    }

function testCreateNFTAuction() public {
    uint256 nftTokenId = 0;

    // Confirmar que el deployer es el propietario antes de crear la subasta
    assertEq(nftExample.ownerOf(nftTokenId), deployer, "Deployer no es el propietario del NFT");

    // Aprobar la transferencia del NFT
    vm.startPrank(deployer);
    nftExample.approve(address(nftAuctionManager), nftTokenId);

    // Verificar que el contrato está aprobado
    assertEq(nftExample.getApproved(nftTokenId), address(nftAuctionManager), "NFT no aprobado correctamente");

    // Llamar la función de creación de subasta
    nftAuctionManager.createNFTAuction(address(nftExample), nftTokenId, 15, NFTAuctionManager.TimeUnit.Minutes);
    vm.stopPrank();

    // Verificar que el propietario del NFT es el contrato de subasta
    address auctionAddress = nftAuctionManager.getAuction(0);
    assertEq(nftExample.ownerOf(nftTokenId), auctionAddress, "El NFT no fue transferido al contrato de subasta");

    // Verificar que la subasta está correctamente configurada
    NFTAuction auction = NFTAuction(auctionAddress);
    assertEq(auction.nftOwner(), deployer, "El deployer no es el propietario original registrado en la subasta");
    }

}

