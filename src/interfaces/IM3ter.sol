// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin/contracts@5.1.0/interfaces/IERC721.sol";

interface IM3ter is IERC721 {
    event Register(uint256 indexed tokenId, bytes32 indexed publicKey, address from, uint256 timestamp);
    event KeyOverwrite(uint256 indexed tokenId, bytes32 indexed publicKey);

    error CannotBeZero();

    function register(uint256 tokenId, bytes32 publicKey) external;
}
