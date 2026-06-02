// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Uranium Finance (Apr 2021, ~$50M). The pair used a 10,000 fee
/// denominator when adjusting balances, but checked the product against
/// `1000 ** 2` instead of `10000 ** 2`, accepting swaps that destroyed almost
/// the entire constant-product invariant.
contract UraniumLikePair {
    uint256 public reserve0;
    uint256 public reserve1;

    function init(uint256 _reserve0, uint256 _reserve1) external {
        require(reserve0 == 0 && reserve1 == 0, "initialized");
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    function swap(uint256 amount0In, uint256 amount1Out) external returns (uint256 adjusted0, uint256 adjusted1) {
        require(amount0In > 0, "no input");
        require(amount1Out > 0 && amount1Out < reserve1, "bad output");

        uint256 balance0 = reserve0 + amount0In;
        uint256 balance1 = reserve1 - amount1Out;

        adjusted0 = balance0 * 10000 - amount0In * 16;
        adjusted1 = balance1 * 10000;

        // Bug: should be `10000 ** 2`. The shipped typo lowered the invariant
        // requirement by 100x.
        require(adjusted0 * adjusted1 >= reserve0 * reserve1 * (1000 ** 2), "K");

        reserve0 = balance0;
        reserve1 = balance1;
    }
}
