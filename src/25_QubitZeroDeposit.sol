// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Qubit bridge (Jan 2022, $80M). When `token == address(0)` (native),
/// the bridge skipped the ERC20 transfer entirely but still credited the
/// caller's xBalance, so any caller could mint xETH for free.
contract QubitLike {
    mapping(address => uint256) public xBalance;

    // Bug: when token is address(0), should require msg.value == amount,
    // but the original implementation just skipped the transferFrom and
    // credited the balance.
    function deposit(address token, uint256 amount) external payable {
        if (token != address(0)) {
            // Pretend an ERC20 transferFrom happens here.
        }
        xBalance[msg.sender] += amount;
    }
}
