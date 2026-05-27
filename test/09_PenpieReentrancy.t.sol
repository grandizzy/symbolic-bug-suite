// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {PenpieLike, IMarketCallback} from "../src/09_PenpieReentrancy.sol";

contract MaliciousMarket is IMarketCallback {
    PenpieLike public master;
    uint256 public claimed;
    bool entered;

    constructor(PenpieLike _master) {
        master = _master;
    }

    function onClaim() external override {
        if (!entered) {
            entered = true;
            // Re-enter to harvest a second time.
            try master.harvest(address(this)) returns (uint256 amount) {
                claimed += amount;
            } catch {}
        }
    }
}

contract PenpieReentrancyTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function checkHarvestCannotBeReplayed(uint256 reward) public {
        if (reward == 0 || reward > 1e30) return;

        PenpieLike master = new PenpieLike();
        MaliciousMarket m = new MaliciousMarket(master);

        master.registerMarket(address(m));
        master.setRewards(address(m), reward);

        vm.prank(address(m));
        try master.harvest(address(m)) {} catch { return; }

        // Soundness: total claimed across reentries must equal the granted reward.
        // The inner reentry would double-count.
        assert(m.claimed() == 0);
    }
}
