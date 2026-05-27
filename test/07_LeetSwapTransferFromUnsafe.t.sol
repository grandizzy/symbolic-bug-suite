// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LeetTokenLike} from "../src/07_LeetSwapTransferFromUnsafe.sol";

contract LeetSwapTransferFromUnsafeTest is Test {
    function checkVictimBalanceNotStealableByThirdParty(address attacker, uint256 amount) public {
        if (amount == 0 || amount > 1e30) return;

        LeetTokenLike token = new LeetTokenLike();
        address victim = address(0xBEEF);
        token.mint(victim, amount);

        // attacker is anyone other than the victim and the test contract.
        if (attacker == victim || attacker == address(this)) return;

        vm.prank(attacker);
        token.transferFromUnsafe(victim, attacker, amount);

        // Soundness: a third party cannot take more than they had.
        assert(token.balanceOf(attacker) == 0);
    }
}
