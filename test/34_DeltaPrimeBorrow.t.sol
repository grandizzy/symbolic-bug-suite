// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {DeltaPrimeLike} from "../src/34_DeltaPrimeBorrow.sol";

contract DeltaPrimeBorrowTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

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
