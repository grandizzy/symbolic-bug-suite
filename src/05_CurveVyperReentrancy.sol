// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Curve / Vyper compiler reentrancy (Jul 2023, $61M). The Vyper
/// nonreentrant lock was miscompiled, so `remove_liquidity` could be
/// re-entered via the native-token transfer callback before LP balances
/// were updated, letting the attacker withdraw the same liquidity twice.
contract CurvePoolLike {
    mapping(address => uint256) public lpBalance;

    function addLiquidity() external payable {
        lpBalance[msg.sender] += msg.value;
    }

    // Bug: pays out before debiting the LP balance, with no reentrancy lock.
    // The historical Vyper miscompilation produced wrapping arithmetic on
    // the post-callback state update; `unchecked` mirrors that behavior so
    // the reentrant double-spend manifests as silent corruption instead of
    // a revert.
    function removeLiquidity(uint256 amount) external {
        require(lpBalance[msg.sender] >= amount, "!bal");
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "!send");
        unchecked {
            lpBalance[msg.sender] -= amount;
        }
    }

    receive() external payable {}
}
