// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BECLike} from "../src/03_BECOverflow.sol";

contract BECOverflowTest is Test {
    function checkAttackerWithoutBalanceCannotMint(uint256 value, address r1, address r2) public {
        // Attacker (this) starts with zero balance.
        BECLike t = new BECLike(address(0xdead), type(uint256).max);

        address[] memory rs = new address[](2);
        rs[0] = r1;
        rs[1] = r2;

        // Ignore degenerate cases where receivers are the funded address.
        if (r1 == address(0xdead) || r2 == address(0xdead) || r1 == r2) return;

        // If batchTransfer succeeds, receivers' combined balance must not increase
        // (attacker had nothing to give).
        try t.batchTransfer(rs, value) {
            assert(t.balanceOf(r1) == 0 && t.balanceOf(r2) == 0);
        } catch {}
    }
}
