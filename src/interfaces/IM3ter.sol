// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

interface IM3ter {
    error CannotBeZero();
    error Unauthorized();

    function setPublicKey(uint256 tokenId, bytes32 publicKey) external;

    function commitState(bytes calldata nonces, bytes calldata totalizers, bytes calldata proof) external;

    function nonce(uint256 tokenId) external view returns (bytes6);

    function totalizer(uint256 tokenId) external view returns (bytes6);
}
