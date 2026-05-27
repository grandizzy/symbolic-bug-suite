// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {KOTELike} from "../src/27_KingOfEtherSendFail.sol";

contract NastyKing {
    receive() external payable {
        revert("nope");
    }
    function claim(KOTELike t) external payable {
        t.claimThrone{value: msg.value}();
    }
}

contract KingOfEtherTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function checkThroneAlwaysClaimable(bool poison) public payable {
        vm.deal(address(this), 1000 ether);
        KOTELike t = new KOTELike();

        if (poison) {
            NastyKing nasty = new NastyKing();
            vm.deal(address(nasty), 10 ether);
            nasty.claim{value: 1 ether}(t);
        } else {
            t.claimThrone{value: 1 ether}();
        }

        // A second legitimate claim must succeed regardless of who the prior king was.
        try t.claimThrone{value: 1 ether}() {} catch {
            assert(false);
        }
    }
}
