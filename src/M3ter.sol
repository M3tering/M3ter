// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "solady@0.1.7/src/tokens/ERC721.sol";
import {OwnableRoles} from "solady@0.1.7/src/auth/OwnableRoles.sol";
import {EnumerableSetLib} from "solady@0.1.7/src/utils/EnumerableSetLib.sol";

import {IM3ter} from "./interfaces/IM3ter.sol";

/// @custom:security-contact info@whynotswitch.com
contract M3ter is ERC721, OwnableRoles, IM3ter {
    using EnumerableSetLib for EnumerableSetLib.Uint256Set;

    EnumerableSetLib.Uint256Set _allTokens;
    mapping(uint256 => string) _tokenURIs;
    mapping(address => EnumerableSetLib.Uint256Set) _ownedTokens;
    uint256 public constant KEYRING_BASE_SLOT = uint256(keccak256("KEYRING"));

    constructor(address defaultAdmin) {
        _initializeOwner(defaultAdmin);
        _grantRoles(defaultAdmin, _ROLE_0);
    }

    function safeMint(uint256 tokenId, address to, string memory uri) external payable onlyRoles(_ROLE_0) {
        _tokenURIs[tokenId] = uri;
        _safeMint(to, tokenId);
    }

    function setPublicKey(uint256 tokenId, bytes32 newKey) external payable {
        emit NewKey(tokenId, newKey, msg.sender, block.timestamp);
        if (msg.sender != ownerOf(tokenId)) revert Unauthorized();
        uint256 slot = KEYRING_BASE_SLOT + tokenId;
        assembly {
            sstore(slot, newKey)
        }
    }

    function publicKey(uint256 tokenId) external view returns (bytes32 key) {
        uint256 slot = KEYRING_BASE_SLOT + tokenId;
        assembly {
            key := sload(slot)
        }
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
        from == address(0) ? _allTokens.add(tokenId) : _ownedTokens[from].remove(tokenId);
        to == address(0) ? _allTokens.remove(tokenId) : _ownedTokens[to].add(tokenId);
    }
}
