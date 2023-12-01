//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/ILayerZeroReceiver.sol";
import "./NonblockingLzApp.sol";

error NotTokenOwner();
error InsufficientGas();
error AlreadyMinted();
error TokenDoesNotExist();
error OneWayBridge();

contract FrameLayerZeroNFT_Sepolia is Ownable, ERC721, NonblockingLzApp {
    enum STATUS {
        MINTED,
        BRIDGED,
        NEITHER
    }

    // token exists
    mapping(uint256 => bool) public exists;

    // user has minted
    mapping(address => bool) public minted;

    // user has initiated bridge
    mapping(address => bool) public bridged;

    uint256 public currentTokenId;

    string private _tokenURI;

    uint16 public constant FRAME_CHAIN_ID = 10222;

    constructor(
        address _endpoint,
        string memory _uri
    )
        ERC721("Frame LayerZero Testnet NFT", "FLZTNFT")
        NonblockingLzApp(_endpoint)
        Ownable(msg.sender)
    {
        _tokenURI = _uri;
    }

    function mint() external returns (uint256) {
        if (minted[msg.sender]) revert AlreadyMinted();

        exists[currentTokenId] = true;
        minted[msg.sender] = true;

        _mint(msg.sender, currentTokenId);

        // will return then increment
        return currentTokenId++;
    }

    function bridgeToFrame(uint256 tokenId) public payable {
        if (msg.sender != ownerOf(tokenId)) revert NotTokenOwner();

        exists[tokenId] = false;
        _burn(tokenId);

        bytes memory payload = abi.encode(msg.sender, tokenId);
        uint16 version = 1;
        uint256 gasForLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForLzReceive);

        (uint256 messageFee, ) = lzEndpoint.estimateFees(
            FRAME_CHAIN_ID,
            address(this),
            payload,
            false,
            adapterParams
        );
        if (msg.value <= messageFee) revert InsufficientGas();

        // bridged
        bridged[msg.sender] = true;

        _lzSend(
            FRAME_CHAIN_ID,
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams,
            msg.value
        );
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /*_nonce*/,
        bytes memory _payload
    ) internal override {
        revert OneWayBridge();
    }

    // Endpoint.sol estimateFees() returns the fees for the message
    function estimateFees() external view returns (uint256) {
        bytes memory payload = abi.encode(msg.sender, 1); // Use arbitrary token id
        uint16 version = 1;
        uint256 gasForLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForLzReceive);

        (uint256 messageFee, ) = lzEndpoint.estimateFees(
            FRAME_CHAIN_ID,
            address(this),
            payload,
            false,
            adapterParams
        );
        return messageFee;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!exists[tokenId]) revert TokenDoesNotExist();

        return _tokenURI;
    }

    function status(address addr) external view returns (STATUS) {
        if (bridged[addr]) return STATUS.BRIDGED;

        if (minted[addr]) return STATUS.MINTED;

        return STATUS.NEITHER;
    }
}
