// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "./interfaces/IM3ter.sol";
import {IERC165} from "@openzeppelin/contracts@5.1.0/interfaces/IERC165.sol";
import {ERC721} from "@openzeppelin/contracts@5.1.0/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts@5.1.0/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts@5.1.0/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts@5.1.0/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts@5.1.0/token/ERC721/extensions/ERC721URIStorage.sol";
import {AccessControl} from "@openzeppelin/contracts@5.1.0/access/AccessControl.sol";

contract M3ter is IM3ter, ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Pausable, AccessControl, ERC721Burnable {
    mapping(bytes32 => bytes32) public registry;
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant PAUSER = keccak256("PAUSER");
    bytes32 public constant REGISTRAR = keccak256("REGISTRAR");

    constructor() ERC721("M3ter", unicode"〔▸‿◂〕") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REGISTRAR, msg.sender);
        _grantRole(MINTER, msg.sender);
        _grantRole(PAUSER, msg.sender);
    }

    function safeMint(address to, uint256 tokenId, string memory uri) external onlyRole(MINTER) whenNotPaused {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function register(uint256 tokenId, bytes32 publicKey) external onlyRole(REGISTRAR) whenNotPaused {
        if (tokenId == 0 || publicKey == 0) revert CannotBeZero();
        uint256 registeredToken = uint256(registry[publicKey]);
        bytes32 registeredKey = registry[bytes32(tokenId)];
        if ((registeredToken != 0 || registeredKey != 0)) emit KeyOverwrite(registeredToken, registeredKey);

        registry[publicKey] = bytes32(tokenId);
        registry[bytes32(tokenId)] = publicKey;
        emit Register(tokenId, publicKey, msg.sender, block.timestamp);
    }

    function pause() public onlyRole(PAUSER) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER) {
        _unpause();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ar://";
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721, ERC721Enumerable, ERC721URIStorage, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
