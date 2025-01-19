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

import {GatewayFetcher, GatewayRequest} from "@unruggable/gateways@0.1.5/contracts/GatewayFetcher.sol";
import {GatewayFetchTarget} from "@unruggable/gateways@0.1.5/contracts/GatewayFetchTarget.sol";
import {IGatewayVerifier} from "@unruggable/gateways@0.1.5/contracts/IGatewayVerifier.sol";

contract M3ter is IM3ter, ERC721Enumerable, ERC721URIStorage, ERC721Pausable, ERC721Burnable, AccessControl, GatewayFetchTarget {
    using GatewayFetcher for GatewayRequest;
    address public immutable CONTRACT = 0x0000000000000000000000000000000000000000; // Todo: set actual contract address
    uint256 public constant TALLY_SLOT = 3; // ...see above table 👆
    bytes32 public constant PAUSER = keccak256("PAUSER");
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant CURATOR = keccak256("CURATOR");

    mapping(bytes32 => uint256) public processRegistry;
    mapping(bytes32 => uint256) public keyRegistry;
    mapping(uint256 => Detail) public details;
    IGatewayVerifier[] public verifiers;

    constructor(address defaultAdmin) ERC721("M3ter", unicode"〔▸‿◂〕") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(CURATOR, defaultAdmin);
        _grantRole(MINTER, defaultAdmin);
        _grantRole(PAUSER, defaultAdmin);
    }

    function _curateVerifiers(IGatewayVerifier verifier) external onlyRole(CURATOR) whenNotPaused {
        verifiers.push(verifier);
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

    function read(address source, bytes32 tokenId) external view returns (uint256) {
        if (source == address(0)) revert CannotBeZero();

        // for (uint i=0; i<verifiers.length; i++) {
        //     IGatewayVerifier verifier = verifiers[i];
        //  ToDo: recursively fetch and aggregate data across supported chains 
        // }
        GatewayRequest memory request = GatewayFetcher
        .newRequest(1)       // Specify the number of outputs
        .setTarget(source)   // Specify the contract address
        .setSlot(TALLY_SLOT) // Specify the base slot number
        .push(tokenId)       // Specify the mapping key you want to read
        .follow()            // Update the VM internal slot pointer to point to that key
        .read()              // Read the value 
        .setOutput(0);       // Set it at output index 0

        // The chain specific verifier contract defines the appropriate gateway URL for the request, and then verifies the response.
        fetch(verifiers[1], request, this.callback.selector);
    }

    function callback(bytes[] calldata values, uint8, bytes calldata) external pure returns (uint256) {
        return abi.decode(values[0], (uint256));
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
