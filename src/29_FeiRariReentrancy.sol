// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Fei / Rari Fuse (Apr 2022, $80M). cToken's `borrow` made an
/// external call to the borrowed token before updating internal accounting,
/// letting the attacker reenter `borrow` to drive their collateral usage
/// negative and drain the pool.
interface IToken {
    function callback() external;
}

contract FuseCTokenLike {
    mapping(address => uint256) public borrowOf;
    uint256 public cash;
    address public underlying;

    function setUnderlying(address u) external {
        underlying = u;
    }

    function fund() external payable {
        cash += msg.value;
    }

    // Bug: external call before state update.
    function borrow(uint256 amount) external {
        require(cash >= amount, "!cash");
        cash -= amount;
        IToken(underlying).callback();
        borrowOf[msg.sender] += amount;
    }
}
