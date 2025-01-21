// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;

import {IM3terContext} from "./interfaces/IM3terContext.sol";
import {IERC721} from "@openzeppelin/contracts@5.1.0/interfaces/IERC721.sol";
import {AccessControl} from "@openzeppelin/contracts@5.1.0/access/AccessControl.sol";

contract M3terContext is IM3terContext, AccessControl {
    bytes32 public constant CURATOR = keccak256("CURATOR");
    IERC721 M3TER = IERC721(0x0000000000000000000000000000000000000000); // ToDo: set actual m3ter contract

    mapping(bytes32 => uint256) public processRegistry;
    mapping(bytes32 => uint256) public keyRegistry;
    mapping(uint256 => bytes32) public l2Allowlist;
    mapping(uint256 => Detail) public details;

    function _curateL2Allowlist(uint256 chainId, bytes32 l2Address) external onlyRole(CURATOR) {
        l2Allowlist[chainId] = l2Address;
    }

    function setup(
        uint256 tokenId,
        bytes32 publicKey,
        bytes32 processId,
        uint256 tariff,
        uint256 escalator,
        uint256 interval
    ) external {
        if (msg.sender != M3TER.ownerOf(tokenId)) revert Unauthorized();
        if (tokenId == 0 || publicKey == 0 || processId == 0 || tariff == 0) revert CannotBeZero();
        details[tokenId] = Detail(tokenId, publicKey, processId, tariff, escalator, interval, block.number);

        emit Register(tokenId, publicKey, msg.sender, block.timestamp);
        processRegistry[processId] = tokenId;
        keyRegistry[publicKey] = tokenId;
    }
}
