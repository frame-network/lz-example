//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/ILayerZeroReceiver.sol";
import "./NonblockingLzApp.sol";

error TokenDoesNotExist();

contract FrameLayerZeroNFT_Frame is Ownable, ERC721, NonblockingLzApp {
    event ReceivedNFT(uint16 _srcChainId, address _from, uint256 _tokenId);

    // user has bridged over successfully
    mapping(address => bool) public bridged;

    // tokenID exists
    mapping(uint256 => bool) public exists;

    string private _tokenURI;

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

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /*_nonce*/,
        bytes memory _payload
    ) internal override {
        address from;
        assembly {
            from := mload(add(_srcAddress, 20))
        }
        (address toAddress, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );

        bridged[toAddress] = true;
        exists[tokenId] = true;

        _mint(toAddress, tokenId);

        emit ReceivedNFT(_srcChainId, from, tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!exists[tokenId]) revert TokenDoesNotExist();
        return _tokenURI;
    }
}
