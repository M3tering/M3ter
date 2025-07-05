// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

interface IRollup {
    event NewState(
        address indexed from,
        uint256 indexed chainLength,
        uint256 indexed anchorBlock,
        bytes totalizerData,
        bytes nonceData,
        bytes proof
    );

    function commitState(
        uint256 anchorBlock,
        bytes calldata totalizerData,
        bytes calldata nonceData,
        bytes calldata proof
    ) external;

    function stateAddress(uint256 at, uint256 io) external view returns (address);

    function totalizer(uint256 tokenId) external view returns (bytes6);

    function nonce(uint256 tokenId) external view returns (bytes6);
}
