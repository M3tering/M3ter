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
    bytes32 public programVKey;
    uint256 public chainLength;

    constructor(address defaultAdmin, bytes32 newProgramVKey) ERC721("M3ter", unicode"〔▸‿◂〕") {
        emit NewState(defaultAdmin, newProgramVKey, 0, block.number, hex"", hex"", hex"");
        SSTORE2.writeDeterministic(hex"00", _pointer(0, 0));
        SSTORE2.writeDeterministic(hex"00", _pointer(0, 1));
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(CURATOR, defaultAdmin);
        _grantRole(MINTER, defaultAdmin);
        setProgramVKey(newProgramVKey);
    }

    function commitState(
        uint256 checkpoint,
        bytes calldata totalizerState,
        bytes calldata nonceState,
        bytes calldata proof
    ) external {
        bytes32 L1Commitment = blockhash(checkpoint);
        if (L1Commitment == 0) revert CannotBeZero(); // blockhash is not available for the given block number

        bytes memory parentStateCommitment =
            abi.encode(stateAddress(chainLength, 0).codehash, stateAddress(chainLength, 1).codehash); // current totalizer & nonce state commitment

        chainLength++;
        // verifies proofs via SP1 Groth16 verifier gateway; reverts here if proof is invalid
        ISP1Verifier(0x397A5f7f3dBd538f23DE225B51f532c34448dA9B).verifyProof(
            programVKey,
            bytes.concat( // public values encoded as bytes
                L1Commitment,
                parentStateCommitment,
                SSTORE2.writeDeterministic(totalizerState, _pointer(chainLength, 0)).codehash,
                SSTORE2.writeDeterministic(nonceState, _pointer(chainLength, 1)).codehash
            ),
            proof
        );
        emit NewState(msg.sender, programVKey, chainLength, checkpoint, totalizerState, nonceState, proof);
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

    function totalizer(uint256 tokenId) external view returns (bytes6) {
        return _stateOf(tokenId, 0);
    }

    function nonce(uint256 tokenId) external view returns (bytes6) {
        return _stateOf(tokenId, 1);
    }

    function setProgramVKey(bytes32 newProgramVKey) public onlyRole(CURATOR) {
        if (newProgramVKey == 0) revert CannotBeZero();
        programVKey = newProgramVKey;
    }

    function stateAddress(uint256 at, uint256 io) public view returns (address) {
        return SSTORE2.predictDeterministicAddress(_pointer(at, io));
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

    function _stateOf(uint256 tokenId, uint256 io) private view returns (bytes6) {
        address pointer = stateAddress(chainLength, io);
        if (tokenId == 0) return bytes6(SSTORE2.read(pointer, 0, 5));
        uint256 index = (tokenId * 6) - 1;
        return bytes6(SSTORE2.read(pointer, index, index + 6));
    }

    function _pointer(uint256 at, uint256 io) private pure returns (bytes32) {
        return bytes32(abi.encodePacked(io == 0 ? this.totalizer.selector : this.nonce.selector, uint224(at)));
    }
}
