// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DODOLike} from "../src/24_DODOReInit.sol";

contract DODOReInitTest is Test {
    function checkInitOnlyOnce(address attacker, address attackerAdmin) public {
        address legit = address(0xC0DE);
        DODOLike d = new DODOLike();
        d.init(legit, 1_000);

        if (attacker == legit) return;

        vm.prank(attacker);
        d.init(attackerAdmin, 0);

        assert(d.admin() == legit);
    }
}
