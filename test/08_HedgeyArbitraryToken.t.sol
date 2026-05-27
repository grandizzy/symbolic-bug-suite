// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {HedgeyLike} from "../src/08_HedgeyArbitraryToken.sol";

contract HedgeyArbitraryTokenTest is Test {
    function checkOnlyPlanOwnerCanRedeem(address attacker) public payable {
        uint256 amount = 1 ether;
        vm.deal(address(this), 1000 ether);

        HedgeyLike vault = new HedgeyLike();
        address victim = address(0xBEEF);
        vm.deal(victim, amount);
        vm.prank(victim);
        vault.deposit{value: amount}();

        if (attacker == victim || attacker == address(this) || attacker == address(0)) return;

        vm.prank(attacker);
        try vault.redeemPlan(victim, amount) {} catch { return; }

        // Soundness: attacker should not be able to drain victim's plan.
        assert(vault.balance(victim) == amount);
    }
}
