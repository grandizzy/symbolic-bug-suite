// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CauldronLike} from "../src/15_AbracadabraLiquidation.sol";

contract AbracadabraLiquidationTest is Test {
    function checkLiquidationClearsAtMostRepay(uint256 repay) public {
        // Concrete unhealthy position; only repay amount is symbolic.
        uint256 startCollateral = 50;
        uint256 startBorrow = 100;

        CauldronLike c = new CauldronLike();
        address victim = address(0xBEEF);
        c.open(victim, startCollateral, startBorrow);

        c.liquidate(victim, repay);

        // Soundness: residual debt must equal old debt minus what was repaid
        // (clamped at zero). Anything less than that is a free debt write-off.
        uint256 expected = repay >= startBorrow ? 0 : startBorrow - repay;
        assert(c.borrow(victim) >= expected);
    }
}
