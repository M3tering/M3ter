// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

interface IM3ter {
    error CannotBeZero();
    error Unauthorized();

    event NewState(
        address indexed from,
        bytes32 indexed programVKey,
        uint256 indexed chainLength,
        uint256 checkpoint,
        bytes totalizerState,
        bytes nonceState,
        bytes proof
    );

    event NewKey(uint256 indexed tokenId, bytes32 indexed publicKey, address from, uint256 timestamp);

    function commitState(
        uint256 checkpoint,
        bytes calldata totalizerState,
        bytes calldata nonceState,
        bytes calldata proof
    ) external;

    function stateAddress(uint256 at, uint256 io) external view returns (address);

    function safeMint(uint256 tokenId, address to, string memory uri) external;

    function setPublicKey(uint256 tokenId, bytes32 publicKey) external;

    function totalizer(uint256 tokenId) external view returns (bytes6);

    function nonce(uint256 tokenId) external view returns (bytes6);

    function setProgramVKey(bytes32 newProgramVKey) external;
}
