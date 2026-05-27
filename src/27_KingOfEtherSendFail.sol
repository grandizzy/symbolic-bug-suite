// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice King of the Ether Throne (Feb 2016). Royalty payments to the
/// previous king used a non-payable transfer; if the previous king was a
/// contract whose receive reverted, the new claim path reverted, breaking
/// the contract's intended progression.
contract KOTELike {
    address payable public king;
    uint256 public claimPrice = 1 ether;

    function claimThrone() external payable {
        require(msg.value >= claimPrice, "!fee");
        if (king != address(0)) {
            // Bug: one bad king blocks all future claims forever.
            king.transfer(msg.value);
        }
        king = payable(msg.sender);
    }
}
