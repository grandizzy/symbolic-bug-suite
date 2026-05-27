// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {KiloExLike} from "../src/13_KiloExSetPrices.sol";

contract KiloExSetPricesTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function checkOnlyKeeperCanWritePrice(address attacker, uint256 productId, uint256 attackerPrice)
        public
    {
        address keeper = address(0xC0DEAA);
        KiloExLike px = new KiloExLike(keeper);

        if (attacker == keeper) return;

        vm.prank(attacker);
        px.setPrices(productId, attackerPrice);

        // Soundness: a non-keeper should not be able to write prices.
        assert(px.price(productId) == 0);
    }
}
