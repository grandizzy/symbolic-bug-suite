// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {MunchablesLike} from "../src/12_MunchablesUpgrader.sol";

contract MunchablesUpgraderTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function checkInitializeIsOneShot(address attacker, address attackerImpl) public {
        address legitOwner = address(0xC0DE);
        MunchablesLike m = new MunchablesLike();
        m.initialize(legitOwner);

        if (attacker == legitOwner) return;

        // Attacker re-initializes to themselves, then upgrades.
        vm.prank(attacker);
        m.initialize(attacker);
        vm.prank(attacker);
        try m.upgrade(attackerImpl) {} catch { return; }

        // Soundness: ownership and implementation must not be reassignable
        // by a non-owner after the first initialization.
        assert(m.owner() == legitOwner);
    }
}
