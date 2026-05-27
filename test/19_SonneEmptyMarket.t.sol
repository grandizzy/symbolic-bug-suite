// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {SonneVaultLike} from "../src/19_SonneEmptyMarket.sol";

contract SonneEmptyMarketTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function checkVictimDepositMintsAtLeastOneShareSonne(uint256 victimDeposit) public {
        if (victimDeposit == 0 || victimDeposit > 2_000) return;

        SonneVaultLike pool = new SonneVaultLike();
        pool.deposit(1);
        pool.donate(1_000);

        vm.prank(address(0xBEEF));
        uint256 victimShares = pool.deposit(victimDeposit);

        assert(victimShares > 0);
    }
}
