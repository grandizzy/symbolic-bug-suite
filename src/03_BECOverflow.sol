// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice BeautyChain (BEC, Apr 2018). `batchTransfer(receivers, value)`
/// computed `amount = cnt * value` without overflow checks (pre-0.8 SafeMath
/// missing here), letting an attacker mint near-infinite tokens by picking
/// two receivers and `value = 2**255`.
contract BECLike {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    constructor(address initial, uint256 amount) {
        balanceOf[initial] = amount;
        totalSupply = amount;
    }

    function batchTransfer(address[] memory receivers, uint256 value) external returns (bool) {
        uint256 cnt = receivers.length;
        // Mimic the historical Solidity ^0.4.x unchecked semantics.
        unchecked {
            uint256 amount = cnt * value;
            require(cnt > 0 && cnt <= 20);
            require(balanceOf[msg.sender] >= amount);
            balanceOf[msg.sender] -= amount;
            for (uint256 i = 0; i < cnt; i++) {
                balanceOf[receivers[i]] += value;
            }
        }
        return true;
    }
}
