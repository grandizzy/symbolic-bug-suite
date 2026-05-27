// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Velocore (Jun 2024, $6.8M). The fee path performed
/// `feeMultiplier - 100` without ensuring `feeMultiplier >= 100`, wrapping
/// around `uint256` and crediting the attacker with an enormous LP balance.
contract VelocoreLike {
    mapping(address => uint256) public lpBalance;

    // Bug: `unchecked` block subtracts without lower-bound check. The
    // historical bug was hidden behind a path where `feeMultiplier` was
    // attacker-controllable via a flashloan-priced state.
    function withdrawWithFee(uint256 amount, uint256 feeMultiplier) external {
        unchecked {
            uint256 wrapped = feeMultiplier - 100;
            // Credit a "rebate" proportional to the wrapped delta.
            lpBalance[msg.sender] += amount + wrapped;
        }
    }
}
