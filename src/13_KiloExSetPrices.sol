// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice KiloEx (Apr 2025, $7M). The `setPrices` endpoint was missing the
/// `onlyKeeper` modifier in production, letting any caller post arbitrary
/// price updates. The attacker pushed favorable prices then traded against
/// them.
contract KiloExLike {
    address public keeper;
    mapping(uint256 => uint256) public price;

    constructor(address _keeper) {
        keeper = _keeper;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper, "!keeper");
        _;
    }

    // Bug: missing `onlyKeeper` modifier.
    function setPrices(uint256 productId, uint256 newPrice) external /* onlyKeeper */ {
        price[productId] = newPrice;
    }
}
