// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IM3ter} from "./interfaces/IM3ter.sol";

import {ERC721} from "solady@0.1.7/src/tokens/ERC721.sol";
import {LibString} from "solady@0.1.7/src/utils/LibString.sol";
import {OwnableRoles} from "solady@0.1.7/src/auth/OwnableRoles.sol";
import {EnumerableSetLib} from "solady@0.1.7/src/utils/EnumerableSetLib.sol";


contract PublicKeyring {
    mapping(uint256 => bytes32) public key;
}

/// @title M3ter
/// @custom:security-contact info@whynotswitch.com
contract M3ter is IM3ter, PublicKeyring,ERC721, OwnableRoles {
    using EnumerableSetLib for EnumerableSetLib.Uint256Set;
    using LibString for uint256;

    EnumerableSetLib.Uint256Set private _allTokens;
    mapping(address => EnumerableSetLib.Uint256Set) private _ownedTokens;
    mapping(uint256 => string) private _tokenURIs;

    uint256 public constant MINTER = _ROLE_0;

    constructor(address defaultAdmin) {
        _initializeOwner(defaultAdmin);
        _grantRoles(defaultAdmin, MINTER);
    }

    function safeMint(uint256 tokenId, address to, string memory uri) external onlyRoles(MINTER) {
        _safeMint(to, tokenId);
        _tokenURIs[tokenId] = uri;
    }

    function setPublicKey(uint256 tokenId, bytes32 publicKey) external {
        if (msg.sender != ownerOf(tokenId)) revert Unauthorized();
        if (publicKey == bytes32(0)) revert CannotBeZero();
        key[tokenId] = publicKey;
        emit NewKey(tokenId, publicKey, msg.sender, block.timestamp);
    }

    function totalSupply() external view returns (uint256) {
        return _allTokens.length();
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        return _allTokens.at(index);
    }

    function tokenOfOwnerByIndex(address account, uint256 index) external view returns (uint256) {
        return _ownedTokens[account].at(index);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory uri = _tokenURIs[tokenId];
        if (bytes(uri).length == 0) {
            return string.concat("ar://", tokenId.toString());
        }
        return uri;
    }

    function name() public pure override returns (string memory) {
        return "M3ter";
    }

    function symbol() public pure override returns (string memory) {
        return unicode"〔▸‿◂〕";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if (from == address(0)) {
            // Mint: add to global set
            _allTokens.add(tokenId);
        } else if (from != to) {
            // Transfer out: remove from owner
            _ownedTokens[from].remove(tokenId);
        }

        if (to == address(0)) {
            // Burn: remove from global set
            _allTokens.remove(tokenId);
        } else if (to != from) {
            // Transfer in: add to new owner
            _ownedTokens[to].add(tokenId);
        }
    }
}
