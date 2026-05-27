// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {VaultLike} from "../src/06_HundredEmptyMarket.sol";

contract HundredEmptyMarketTest is Test {
    function checkVictimDepositMintsAtLeastOneShare(uint256 victimDeposit) public {
        // Bounded to keep the SMT instance tractable; the bug appears at any
        // deposit smaller than the donated amount.
        if (victimDeposit == 0 || victimDeposit > 2_000) return;

        VaultLike pool = new VaultLike();
        address attacker = address(this);
        address victim = address(0xBEEF);

        // Classic empty-market priming.
        pool.deposit(1);
        pool.donate(1_000);

        vm.prank(victim);
        uint256 victimShares = pool.deposit(victimDeposit);

        // Soundness: any non-zero deposit must mint a non-zero share, otherwise
        // the depositor's funds are silently absorbed by existing shareholders.
        assert(victimShares > 0);
        attacker; // silence unused-warning if compiler complains
    }
}
