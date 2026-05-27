// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DeltaPrimeLike} from "../src/34_DeltaPrimeBorrow.sol";

contract DeltaPrimeBorrowTest is Test {
    function checkBorrowOnlyByOwner(address attacker, uint256 amount) public {
        if (amount == 0 || amount > 1e30) return;

        address legit = address(0xC0DE);
        DeltaPrimeLike d = new DeltaPrimeLike(legit);

        if (attacker == legit) return;

        vm.prank(attacker);
        d.borrowFromPool(amount);

        // Soundness: a non-owner should not be able to take on debt for the owner.
        assert(d.debt(legit) == 0);
    }
}
