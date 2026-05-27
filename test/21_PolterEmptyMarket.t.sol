// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PolterVaultLike} from "../src/21_PolterEmptyMarket.sol";

contract PolterEmptyMarketTest is Test {
    function checkVictimDepositMintsAtLeastOneSharePolter(uint256 victimDeposit) public {
        if (victimDeposit == 0 || victimDeposit > 2_000) return;

        PolterVaultLike pool = new PolterVaultLike();
        pool.deposit(1);
        pool.donate(1_000);

        vm.prank(address(0xBEEF));
        uint256 victimShares = pool.deposit(victimDeposit);

        assert(victimShares > 0);
    }
}
