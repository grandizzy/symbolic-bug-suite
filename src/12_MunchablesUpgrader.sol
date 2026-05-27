// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Munchables (Mar 2024, $62M). The contract's `initialize` lacked
/// a "already initialized" guard, letting anyone re-initialize it and
/// become the upgrader. The attacker then pointed `implementation` at a
/// contract that returned arbitrary balances.
contract MunchablesLike {
    address public owner;
    address public implementation;

    // Bug: missing `initialized` flag / `initializer` modifier.
    function initialize(address _owner) external {
        owner = _owner;
    }

    function upgrade(address newImpl) external {
        require(msg.sender == owner, "!owner");
        implementation = newImpl;
    }
}
