// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

interface IM3ter {
    error CannotBeZero();
    error Unauthorized();

    event NewState(
        address indexed from,
        uint256 indexed chainLength,
        bytes32 anchorBlockHash,
        bytes32 programVKey,
        bytes32 nonceCodeHash,
        bytes32 totalizerCodeHash,
        bytes proof
    );

    event NewKey(uint256 indexed tokenId, bytes32 indexed publicKey, address from, uint256 timestamp);

    function commitState(bytes calldata nonces, bytes calldata totalizers, bytes calldata proof) external;

    function setPublicKey(uint256 tokenId, bytes32 publicKey) external;

    function safeMint(uint256 tokenId, address to, string memory uri) external;

    function nonce(uint256 tokenId) external view returns (bytes6);

    function totalizer(uint256 tokenId) external view returns (bytes6);

    function _setProgramVKey(bytes32 newProgramVKey) external;
}
