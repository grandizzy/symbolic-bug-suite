// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Penpie / Pendle (Sep 2024, $27M). Attacker registered a malicious
/// market with the master, then claimed rewards through it. The reward
/// callback fired before rewards were zeroed, letting the attacker re-enter
/// and claim again on the same balance.
interface IMarketCallback {
    function onClaim() external;
}

contract PenpieLike {
    mapping(address => uint256) public rewards;
    mapping(address => bool) public registeredMarket;

    function setRewards(address user, uint256 amount) external {
        rewards[user] += amount;
    }

    // Bug: anyone can register a market, and harvest calls back to the
    // market before zeroing rewards.
    function registerMarket(address market) external {
        registeredMarket[market] = true;
    }

    function harvest(address market) external returns (uint256 amount) {
        require(registeredMarket[market], "!registered");
        amount = rewards[msg.sender];
        require(amount > 0, "!amount");
        IMarketCallback(market).onClaim();
        // State update after external call.
        rewards[msg.sender] = 0;
    }
}
