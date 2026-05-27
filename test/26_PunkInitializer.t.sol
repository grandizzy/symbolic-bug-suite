// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {PunkLike} from "../src/26_PunkInitializer.sol";

contract PunkInitializerTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function checkInitNotRecallable(address attacker, address attackerOwner) public {
        address legit = address(0xC0DE);
        PunkLike p = new PunkLike();
        p.__init(legit);

        if (attacker == legit) return;

        vm.prank(attacker);
        p.__init(attackerOwner);

        assert(p.owner() == legit);
    }
}
