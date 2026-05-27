// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Abracadabra cauldron (Mar 2025, $13M). The liquidation path
/// fully cleared the victim's debt regardless of the repayment amount,
/// letting an attacker zero out a large debt by repaying a single wei.
contract CauldronLike {
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public borrow;

    function open(address user, uint256 c, uint256 b) external {
        collateral[user] = c;
        borrow[user] = b;
    }

    // Bug: borrow is set to 0 even when liquidator pays back only part of it.
    function liquidate(address victim, uint256 repay) external returns (uint256 seized) {
        require(borrow[victim] > collateral[victim], "healthy");
        seized = repay > collateral[victim] ? collateral[victim] : repay;
        collateral[victim] -= seized;
        borrow[victim] = 0;
    }
}
