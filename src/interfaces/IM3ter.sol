// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin/contracts@5.1.0/interfaces/IERC721.sol";

interface IM3ter is IERC721 {
    struct Detail {
        // Identifiers
        uint256 tokenId;
        bytes32 publicKey;
        bytes32 processId;
        // Terms of Use
        uint256 tariff;
        uint256 escalator;
        uint256 blockInterval;
        uint256 lastCheckpoint;
    }

    event Register(uint256 indexed tokenId, bytes32 indexed publicKey, address from, uint256 timestamp);

    error CannotBeZero();
    error Unauthorized();

    function setup(
        uint256 tokenId,
        bytes32 publicKey,
        bytes32 processId,
        uint256 tariff,
        uint256 escalator,
        uint256 interval
    ) external;
}
