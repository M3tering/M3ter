// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts@4.9.3/utils/Counters.sol";
import "./DEX/DAI2SLX.sol";
import "./XRC721.sol";
import "./interfaces/IM3ter.sol";

/// @custom:security-contact info@whynotswitch.com
contract M3ter is XRC721, IM3ter {
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");
    uint256 public mintFee = 250 * 10 ** 18;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => uint256) public tokenRegistry;
    mapping(uint256 => uint256) public keyDirectory;

    constructor() ERC721("M3ter", "M3R") {
        if (address(DAI2SLX.MIMO) == address(0)) revert ZeroAddress();
        if (address(DAI2SLX.DAI) == address(0)) revert ZeroAddress();
        if (address(DAI2SLX.SLX) == address(0)) revert ZeroAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REGISTRAR_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _tokenIdCounter.increment();
    }

    function mint() external whenNotPaused {
        DAI2SLX.depositDAI(mintFee);
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function _setMintFee(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintFee = amount;
    }

    function _register(
        uint256 tokenId,
        uint256 publicKey
    ) external onlyRole(REGISTRAR_ROLE) {
        if (!_exists(tokenId)) revert NonexistentM3ter();
        emit Register(tokenId, publicKey, block.timestamp, msg.sender);
        tokenRegistry[tokenId] = publicKey;
        keyDirectory[publicKey] = tokenId;
    }

    function _claim(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        DAI2SLX.claimSLX(amountIn, amountOutMin, deadline);
    }
}
