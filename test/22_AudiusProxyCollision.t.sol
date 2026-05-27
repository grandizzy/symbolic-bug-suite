// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AudiusLike} from "../src/22_AudiusProxyCollision.sol";

contract AudiusProxyCollisionTest is Test {
    function checkAdminCannotBeRewrittenByAnyCaller(address attacker, uint256 newPeriod) public {
        address legitAdmin = address(0xC0DE);
        AudiusLike a = new AudiusLike(legitAdmin);

        if (attacker == legitAdmin) return;

        vm.prank(attacker);
        a.setVotingPeriod(newPeriod);

        // Soundness: the admin slot must not be reassignable by a third party.
        assert(a.admin() == legitAdmin);
    }
}
