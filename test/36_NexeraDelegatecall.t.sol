// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {NexeraLike} from "../src/36_NexeraDelegatecall.sol";

contract AdminSwapper {
    address public admin;
    function setAdmin(address a) external {
        admin = a;
    }
}

contract NexeraDelegatecallTest is Test {
    function checkUpgradeRestrictedToAdmin(address attacker) public {
        address legit = address(0xC0DE);
        NexeraLike n = new NexeraLike(legit);
        AdminSwapper s = new AdminSwapper();

        if (attacker == legit || attacker == address(0)) return;

        vm.prank(attacker);
        n.upgradeAndCall(address(s), abi.encodeCall(AdminSwapper.setAdmin, (attacker)));

        // Soundness: a non-admin should not be able to overwrite admin via upgrade.
        assert(n.admin() == legit);
    }
}
