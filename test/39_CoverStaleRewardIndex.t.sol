// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CoverLikeBlacksmith} from "../src/39_CoverStaleRewardIndex.sol";

contract CoverStaleRewardIndexTest is Test {
    function checkNewStakeCannotClaimOldRewards(uint16 attackerDeposit) public {
        if (attackerDeposit == 0 || attackerDeposit > 1_000) return;

        CoverLikeBlacksmith blacksmith = new CoverLikeBlacksmith();
        address honestLp = address(0xA11CE);
        address attacker = address(this);

        vm.prank(honestLp);
        blacksmith.deposit(1_000);

        uint256 oldRewards = 1_000;
        blacksmith.queueRewards(oldRewards);

        blacksmith.deposit(attackerDeposit);
        blacksmith.claimRewards();

        // Soundness: rewards queued before this stake existed belong to the
        // existing LP set; a new stake should not mint any of them.
        assert(blacksmith.mintedRewards(attacker) == 0);
    }
}
