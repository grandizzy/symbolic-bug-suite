// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice MonoX (Nov 2021, $31M). The swap path didn't reject `tokenIn == tokenOut`,
/// so an attacker called `swap(X, X, amount)` and the intermediate price update
/// to the same token pumped the read-back price arbitrarily.
contract MonoXLike {
    mapping(address => uint256) public price;
    mapping(address => uint256) public reserves;

    function init(address t, uint256 reserve, uint256 px) external {
        reserves[t] = reserve;
        price[t] = px;
    }

    // Bug: no `require(tIn != tOut)` check.
    function swap(address tIn, address tOut, uint256 amountIn) external returns (uint256 out) {
        // Update price[tIn] *first*, then read price[tOut] for the payout calc.
        price[tIn] = (price[tIn] * reserves[tIn]) / (reserves[tIn] + amountIn);
        // If tIn == tOut, attacker just rewrote price[tOut] downward to make
        // out = amountIn * old_price / new_price → arbitrarily large.
        out = (amountIn * 1e18) / price[tOut];
        reserves[tOut] -= out;
    }
}
