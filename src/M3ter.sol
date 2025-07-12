// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IM3ter} from "./interfaces/IM3ter.sol";

import {ERC721} from "solady@0.1.7/src/tokens/ERC721.sol";
import {OwnableRoles} from "solady@0.1.7/src/auth/OwnableRoles.sol";
import {EnumerableSetLib} from "solady@0.1.7/src/utils/EnumerableSetLib.sol";

/// @custom:security-contact info@whynotswitch.com
contract M3ter is ERC721, OwnableRoles, IM3ter {
    using EnumerableSetLib for EnumerableSetLib.Uint256Set;

    mapping(uint256 => bytes32) public key;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => EnumerableSetLib.Uint256Set) private _ownedTokens;
    EnumerableSetLib.Uint256Set private _allTokens;

    constructor(address defaultAdmin) {
        _initializeOwner(defaultAdmin);
        _grantRoles(defaultAdmin, _ROLE_0);
    }

    function safeMint(uint256 tokenId, address to, string memory uri) external onlyRoles(_ROLE_0) {
        _tokenURIs[tokenId] = uri;
        _safeMint(to, tokenId);
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
        return _tokenURIs[tokenId];
    }

    function name() public pure override returns (string memory) {
        return "M3ter";
    }

    function symbol() public pure override returns (string memory) {
        return unicode"〔▸‿◂〕";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if (from == address(0)) {
            _allTokens.add(tokenId);
        } else if (from != to) {
            _ownedTokens[from].remove(tokenId);
        }

        if (to == address(0)) {
            _allTokens.remove(tokenId);
        } else if (to != from) {
            _ownedTokens[to].add(tokenId);
        }
    }
}
