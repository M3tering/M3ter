// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

import {SSTORE2} from "solady/src/utils/SSTORE2.sol";

import {ISP1Verifier} from "./interfaces/ISP1Verifier.sol";
import {IRollup} from "./interfaces/IRollup.sol";

/// @custom:security-contact info@whynotswitch.com
contract Rollup is IRollup {
    uint256 public chainLength;

    constructor() {
        emit NewState(msg.sender, 0, 0, hex"", hex"", hex"");
        SSTORE2.writeDeterministic(hex"00", _pointer(0, 0));
        SSTORE2.writeDeterministic(hex"00", _pointer(0, 1));
    }

    function commitState(
        uint256 anchorBlock,
        bytes calldata totalizeData,
        bytes calldata nonceData,
        bytes calldata proof
    ) external {
        // verifies proofs via SP1 Groth16 verifier gateway; reverts here if proof is invalid
        ISP1Verifier(0x397A5f7f3dBd538f23DE225B51f532c34448dA9B).verifyProof(
            0x1179a1ee553885480360014550c764d67185dd60b242af4928e2f41f3a222cd6, // set to actual SP1 program vKey
            bytes.concat(
                blockhash(anchorBlock), // ethereum state commitment
                stateAddress(chainLength, 0).codehash, // totalizer state commitment
                stateAddress(chainLength, 1).codehash, // nonce state commitment
                hex"00", totalizeData, // proposed state blob
                hex"00", nonceData // proposed state blob
            ),
            proof
        );

        chainLength++;
        emit NewState(msg.sender, chainLength, anchorBlock, totalizeData, nonceData, proof);
        SSTORE2.writeDeterministic(totalizeData, _pointer(chainLength, 0));
        SSTORE2.writeDeterministic(nonceData, _pointer(chainLength, 1));
    }

    function totalizer(uint256 tokenId) external view returns (bytes6) {
        return _stateOf(tokenId, 0);
    }

    function nonce(uint256 tokenId) external view returns (bytes6) {
        return _stateOf(tokenId, 1);
    }

    function stateAddress(uint256 at, uint256 io) public view returns (address) {
        return SSTORE2.predictDeterministicAddress(_pointer(at, io));
    }

    function _stateOf(uint256 tokenId, uint256 io) private view returns (bytes6) {
        address pointer = stateAddress(chainLength, io);
        if (tokenId == 0) return bytes6(SSTORE2.read(pointer, 0, 5));
        uint256 index = (tokenId * 6) - 1;
        return bytes6(SSTORE2.read(pointer, index, index + 6));
    }

    function _pointer(uint256 at, uint256 io) private pure returns (bytes32) {
        return bytes32(abi.encodePacked(io == 0 ? this.totalizer.selector : this.nonce.selector, uint224(at)));
    }
}
