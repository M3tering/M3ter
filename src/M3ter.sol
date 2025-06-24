// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

import {SSTORE2} from "solady/src/utils/SSTORE2.sol";

import {ERC721} from "@openzeppelin/contracts@5.1.0/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts@5.1.0/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts@5.1.0/token/ERC721/extensions/ERC721URIStorage.sol";
import {AccessControl} from "@openzeppelin/contracts@5.1.0/access/AccessControl.sol";

import {ISP1Verifier} from "./interfaces/ISP1Verifier.sol";

/// @custom:security-contact info@whynotswitch.com
contract M3ter is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32[4095] public key; // m3ter public keys
    bytes32 anchorBlockhash;
    uint256 chainLength;

    error CannotBeZero();
    error Unauthorized();
    constructor(address defaultAdmin, string memory token0Uri) ERC721("M3ter", unicode"〔▸‿◂〕") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER, defaultAdmin);
        _safeMint(defaultAdmin, 0);
        _setTokenURI(0, token0Uri);

        SSTORE2.writeDeterministic(hex"00", _ref(0));
        SSTORE2.writeDeterministic(hex"00", _ref(1));
        anchorBlockhash = blockhash(block.number - 1);
    }

    function safeMint(address to, uint256 tokenId, string memory uri) external onlyRole(MINTER) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function commitState(bytes calldata nonces, bytes calldata totalizers, bytes calldata proof) external {
        bytes32 priorNonces = SSTORE2.predictDeterministicAddress(_ref(0)).codehash;
        bytes32 priorTotalizers = SSTORE2.predictDeterministicAddress(_ref(1)).codehash;

        ++chainLength;
        bytes32 proposedNonces = SSTORE2.writeDeterministic(nonces, _ref(0)).codehash;
        bytes32 proposedTotalizers = SSTORE2.writeDeterministic(totalizers, _ref(1)).codehash;

        // verifies proofs; reverts here if proof is invalid
        ISP1Verifier(0x397A5f7f3dBd538f23DE225B51f532c34448dA9B).verifyProof( // SP1 Groth16 verifier gateway
            0x005d5c8cead52bd80a671d8e7d603ed8cb867ee8987d409e6f8bce000ee91c68, // SP1 programVKey
            bytes.concat(anchorBlockhash, priorNonces, priorTotalizers, proposedNonces, proposedTotalizers),
            proof
        );
        anchorBlockhash = blockhash(block.number - 1);
    }

    function nonce(uint256 tokenId) external view returns (uint256) {
        return uint256(bytes32(SSTORE2.read(SSTORE2.predictDeterministicAddress(_ref(0)), tokenId * 6, ++tokenId * 6)));
    }

    function totalizer(uint256 tokenId) external view returns (uint256) {
        return uint256(bytes32(SSTORE2.read(SSTORE2.predictDeterministicAddress(_ref(1)), tokenId * 6, ++tokenId * 6)));
    }

    function setPublicKey(uint256 tokenId, bytes32 publicKey) external {
        if (msg.sender != ownerOf(tokenId)) revert Unauthorized();
        if (tokenId == 0 || publicKey == 0) revert CannotBeZero();
        key[tokenId] = publicKey;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
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

    function _ref(uint256 x) private view returns (bytes32) {
        return bytes32(abi.encodePacked(x == 0 ? this.nonce.selector : this.totalizer.selector, uint224(chainLength)));
    }
}
