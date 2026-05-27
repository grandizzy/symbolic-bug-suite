// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {HolographLike} from "../src/11_HolographMissingOp.sol";

contract HolographMissingOpTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function checkOnlyOperatorCanMint(address attacker, uint256 amount) public {
        if (amount == 0 || amount > 1e30) return;

        address operator = address(0xCAFE);
        HolographLike token = new HolographLike(operator);

        if (attacker == operator) return;

        vm.prank(attacker);
        token.bridgeIn(attacker, amount);

        // Soundness: a non-operator should not be able to mint themselves tokens.
        assert(token.balanceOf(attacker) == 0);
    }
}
