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

contract M3ter is IM3ter, ERC721Enumerable, ERC721URIStorage, ERC721Pausable, ERC721Burnable, AccessControl {
    bytes32 public constant PAUSER = keccak256("PAUSER");
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant CURATOR = keccak256("CURATOR");

    mapping(bytes32 => uint256) public processRegistry;
    mapping(bytes32 => uint256) public keyRegistry;
    mapping(uint256 => bytes32) public l2Allowlist;
    mapping(uint256 => Detail) public details;

    constructor(address defaultAdmin) ERC721("M3ter", unicode"〔▸‿◂〕") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER, defaultAdmin);
        _grantRole(PAUSER, defaultAdmin);
    }

    function _curateL2Allowlist(uint256 chainId, bytes32 l2Address) external onlyRole(CURATOR) whenNotPaused {
        l2Allowlist[chainId] = l2Address;
    }

    function safeMint(address to, uint256 tokenId, string memory uri) external onlyRole(MINTER) whenNotPaused {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function setup(
        uint256 tokenId,
        bytes32 publicKey,
        bytes32 processId,
        uint256 tariff,
        uint256 escalator,
        uint256 interval
    ) external {
        if (msg.sender != ownerOf(tokenId)) revert Unauthorized();
        if (tokenId == 0 || publicKey == 0 || processId == 0 || tariff == 0) revert CannotBeZero();
        details[tokenId] = Detail(tokenId, publicKey, processId, tariff, escalator, interval, block.number);

        emit Register(tokenId, publicKey, msg.sender, block.timestamp);
        processRegistry[processId] = tokenId;
        keyRegistry[publicKey] = tokenId;
    }

    function pause() public onlyRole(PAUSER) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER) {
        _unpause();
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

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

    function _baseURI() internal pure override returns (string memory) {
        return "ar://";
    }
}
