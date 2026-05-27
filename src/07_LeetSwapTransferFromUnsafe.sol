// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice LeetSwap (Aug 2023, $620K). The pair contract exposed
/// `transferFromUnsafe`, a public function that moved tokens between
/// arbitrary holders without an allowance check. Attackers used it to
/// drain reserves from any LP pair.
contract LeetTokenLike {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    // Bug: no msg.sender check, no allowance check.
    function transferFromUnsafe(address from, address to, uint256 amount) external {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }
}
