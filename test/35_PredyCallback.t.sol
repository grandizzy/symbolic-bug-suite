// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PredyLike} from "../src/35_PredyCallback.sol";

contract PredyCallbackTest is Test {
    function checkSwapCallbackOnlyByPool(address attacker, uint256 amount) public {
        if (amount == 0 || amount > 1e30) return;

        address pool = address(0xC0DE);
        PredyLike p = new PredyLike(pool);

        address victim = address(0xBEEF);
        vm.prank(victim);
        p.deposit(amount);

        if (attacker == pool || attacker == victim) return;

        vm.prank(attacker);
        p.swapCallback(victim, amount);

        // Soundness: only the pool should be able to redirect credit.
        assert(p.credit(attacker) == 0);
    }
}
