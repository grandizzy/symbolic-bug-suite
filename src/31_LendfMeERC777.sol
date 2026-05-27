// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Lendf.Me / dForce (Apr 2020, $25M). ERC-777 `tokensReceived` hook
/// fired during deposit's `transferFrom`, before the deposit's internal
/// accounting was finalized, letting the attacker borrow against
/// not-yet-credited collateral.
interface ITokenReceiver {
    function tokensReceived(address from, address to, uint256 amount) external;
}

contract LendfMeLike {
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public borrowed;

    function deposit(address token, uint256 amount) external {
        // Bug: collateral is credited before the ERC-777 transfer settles;
        // the `tokensReceived` hook lets the attacker re-enter and borrow
        // against the not-yet-paid-for collateral.
        collateral[msg.sender] += amount;
        ITokenReceiver(token).tokensReceived(msg.sender, address(this), amount);
    }

    function borrow(uint256 amount) external {
        require(collateral[msg.sender] >= borrowed[msg.sender] + amount, "!collateral");
        borrowed[msg.sender] += amount;
    }
}
