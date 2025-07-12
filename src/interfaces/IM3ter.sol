// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

interface IM3ter {
    error CannotBeZero();

    event NewKey(uint256 indexed tokenId, bytes32 indexed publicKey, address from, uint256 timestamp);

    function safeMint(uint256 tokenId, address to, string memory uri) external;

    function setPublicKey(uint256 tokenId, bytes32 publicKey) external;
}
