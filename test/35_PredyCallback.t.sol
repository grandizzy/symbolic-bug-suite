// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {PredyLike} from "../src/35_PredyCallback.sol";

contract PredyCallbackTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

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
