// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {PolyLike} from "../src/28_PolyNetworkKeeperChange.sol";

contract PolyNetworkKeeperChangeTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function checkKeeperOnlyChangeableByItself(address attacker) public {
        address legit = address(0xC0DE);
        PolyLike p = new PolyLike(legit);

        if (attacker == legit) return;

        vm.prank(attacker);
        bytes memory data = abi.encodeCall(p.putCurEpochConPubKeyBytes, (attacker));
        p.executeCrossChainMessage(data);

        // Soundness: an external caller should not be able to rotate the keeper
        // via a crafted cross-chain message.
        assert(p.keeper() == legit);
    }
}
