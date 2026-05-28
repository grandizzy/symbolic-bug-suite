// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DEILike} from "../src/34_DEIAllowanceReversal.sol";

contract DEIAllowanceReversalTest is Test {
    function checkBurnFromCannotCreateVictimAllowance(uint256 baitApproval, uint256 stealAmount) public {
        if (baitApproval == 0 || baitApproval > 1_000_000e18) return;
        if (stealAmount == 0 || stealAmount > baitApproval) return;

        DEILike token = new DEILike();
        address attacker = address(this);
        address victim = address(0xBEEF);

        token.mint(victim, 1_000_000e18);

        // The attacker grants an allowance to the victim. This should never
        // authorize the attacker to spend the victim's balance.
        token.approve(victim, baitApproval);
        token.burnFrom(victim, 0);

        token.transferFrom(victim, attacker, stealAmount);

        assert(token.balanceOf(attacker) == 0);
    }
}
