// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

import {PublicKeyring} from "./PublicKeyring.sol";
import {ISP1Verifier} from "./interfaces/ISP1Verifier.sol";
import {IM3ter} from "./interfaces/IM3ter.sol";

import {SSTORE2} from "solady/src/utils/SSTORE2.sol";

import {ERC721} from "@openzeppelin/contracts@5.1.0/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts@5.1.0/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts@5.1.0/token/ERC721/extensions/ERC721URIStorage.sol";
import {AccessControl} from "@openzeppelin/contracts@5.1.0/access/AccessControl.sol";

/// @custom:security-contact info@whynotswitch.com
contract M3ter is IM3ter, PublicKeyring, ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl {
    bytes32 public constant CURATOR = keccak256("CURATOR");
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 anchorBlockHash;
    bytes32 programVKey;
    uint256 chainLength;

    constructor(address defaultAdmin, bytes32 newProgramVkey) ERC721("M3ter", unicode"〔▸‿◂〕") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(CURATOR, defaultAdmin);
        _grantRole(MINTER, defaultAdmin);
        setProgramVKey(newProgramVkey);

        // Initialize the state with empty nonces and totalizers
        SSTORE2.writeDeterministic(hex"00", _ref(0));
        SSTORE2.writeDeterministic(hex"00", _ref(1));
        anchorBlockHash = blockhash(block.number - 1);
        emit NewState(defaultAdmin, chainLength, hex"", hex"", hex"", hex"", hex"");
    }

    function commitState(bytes calldata nonces, bytes calldata totalizers, bytes calldata proof) external {
        bytes32 priorNonces = SSTORE2.predictDeterministicAddress(_ref(0)).codehash;
        bytes32 priorTotalizers = SSTORE2.predictDeterministicAddress(_ref(1)).codehash;

        ++chainLength;
        bytes32 proposedNonces = SSTORE2.writeDeterministic(nonces, _ref(0)).codehash;
        bytes32 proposedTotalizers = SSTORE2.writeDeterministic(totalizers, _ref(1)).codehash;

        // verifies proofs; reverts here if proof is invalid
        ISP1Verifier(0x397A5f7f3dBd538f23DE225B51f532c34448dA9B).verifyProof( // SP1 Groth16 verifier gateway
            programVKey,
            bytes.concat(anchorBlockHash, priorNonces, priorTotalizers, proposedNonces, proposedTotalizers),
            proof
        );

        emit NewState(msg.sender, chainLength, anchorBlockHash, programVKey, proposedNonces, proposedTotalizers, proof);
        anchorBlockHash = blockhash(block.number - 1); // set an anchor for the next state commitment
    }

    function setPublicKey(uint256 tokenId, bytes32 publicKey) external {
        emit NewKey(tokenId, publicKey, msg.sender, block.timestamp);
        if (msg.sender != ownerOf(tokenId)) revert Unauthorized();
        if (publicKey == 0) revert CannotBeZero();
        key[tokenId] = publicKey;
    }

    function safeMint(uint256 tokenId, address to, string memory uri) external onlyRole(MINTER) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function nonce(uint256 tokenId) external view returns (bytes6) {
        return _state(0, tokenId);
    }

    function totalizer(uint256 tokenId) external view returns (bytes6) {
        return _state(1, tokenId);
    }

    function setProgramVKey(bytes32 newProgramVKey) public onlyRole(CURATOR) {
        if (newProgramVKey == 0) revert CannotBeZero();
        programVKey = newProgramVKey;
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

    function _state(uint256 selector, uint256 tokenId) private view returns (bytes6) {
        address pointer = SSTORE2.predictDeterministicAddress(_ref(selector));
        if (tokenId == 0) return bytes6(SSTORE2.read(pointer, 0, 5));

        uint256 index = (tokenId * 6) - 1;
        return bytes6(SSTORE2.read(pointer, index, index + 6));
    }

    function _ref(uint256 x) private view returns (bytes32) {
        return bytes32(abi.encodePacked(x == 0 ? this.nonce.selector : this.totalizer.selector, uint224(chainLength)));
    }
}
