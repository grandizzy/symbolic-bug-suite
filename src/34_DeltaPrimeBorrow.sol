// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice DeltaPrime (Sep 2024, $5.98M). The smart-loan contract's borrow
/// flow was callable from any address; the original onlyOwner check was
/// only enforced on UI-facing entrypoints, not on a private-state
/// `borrowFromPool` function that was left public.
contract DeltaPrimeLike {
    address public owner;
    mapping(address => uint256) public debt;

    constructor(address _owner) {
        owner = _owner;
    }

    // Bug: missing `require(msg.sender == owner)`.
    function borrowFromPool(uint256 amount) external {
        debt[owner] += amount;
    }
}
