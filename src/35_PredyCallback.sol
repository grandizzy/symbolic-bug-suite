// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Predy Finance (late 2024 / early 2025, ~$0.5M). The swap
/// callback handler was missing a check that `msg.sender == pool`,
/// letting any caller mark themselves as having "completed" a swap
/// and consume internal credits.
contract PredyLike {
    address public pool;
    mapping(address => uint256) public credit;

    constructor(address _pool) {
        pool = _pool;
    }

    function deposit(uint256 amount) external {
        credit[msg.sender] += amount;
    }

    // Bug: missing `require(msg.sender == pool)`.
    function swapCallback(address user, uint256 amount) external {
        credit[user] -= amount;
        credit[msg.sender] += amount;
    }
}
