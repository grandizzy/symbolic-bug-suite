// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PunkLike} from "../src/26_PunkInitializer.sol";

contract PunkInitializerTest is Test {
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
