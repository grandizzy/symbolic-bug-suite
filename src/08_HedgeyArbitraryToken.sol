// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Hedgey Finance (Apr 2024, $44.5M). `redeemPlan` accepted a
/// caller-supplied `owner` address but never verified `msg.sender == owner`,
/// so anyone could redeem someone else's vesting plan to themselves.
contract HedgeyLike {
    mapping(address => uint256) public balance;

    function deposit() external payable {
        balance[msg.sender] += msg.value;
    }

    // Bug: missing `require(msg.sender == owner)` check.
    function redeemPlan(address owner, uint256 amount) external {
        require(balance[owner] >= amount, "!bal");
        balance[owner] -= amount;
        payable(msg.sender).transfer(amount);
    }
}
