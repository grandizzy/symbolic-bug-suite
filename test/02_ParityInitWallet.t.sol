// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {ParityWalletLike} from "../src/02_ParityInitWallet.sol";

contract ParityInitWalletTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function checkOwnerOnlyChangedByOwner(address attacker, address newOwner) public {
        ParityWalletLike w = new ParityWalletLike();
        // Legitimate setup: contract deployer takes ownership.
        w.initWallet(address(this));

        // Any other caller should not be able to change ownership.
        if (attacker != address(this)) {
            vm.prank(attacker);
            w.initWallet(newOwner);
            assert(w.owner() == address(this));
        }
    }
}
