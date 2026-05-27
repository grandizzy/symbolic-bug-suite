// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {OnyxVaultLike} from "../src/20_OnyxEmptyMarket.sol";

contract OnyxEmptyMarketTest is Test {
    function checkVictimDepositMintsAtLeastOneShareOnyx(uint256 victimDeposit) public {
        if (victimDeposit == 0 || victimDeposit > 2_000) return;

        OnyxVaultLike pool = new OnyxVaultLike();
        pool.deposit(1);
        pool.donate(1_000);

        vm.prank(address(0xBEEF));
        uint256 victimShares = pool.deposit(victimDeposit);

        assert(victimShares > 0);
    }
}
