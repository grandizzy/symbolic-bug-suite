// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {KiloExLike} from "../src/13_KiloExSetPrices.sol";

contract KiloExSetPricesTest is Test {
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
