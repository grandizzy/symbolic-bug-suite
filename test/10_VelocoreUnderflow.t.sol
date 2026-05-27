// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VelocoreLike} from "../src/10_VelocoreUnderflow.sol";

contract VelocoreUnderflowTest {
    function checkFeeRebateCannotExceedAmount(uint256 amount, uint256 feeMultiplier) public {
        if (amount > 1e18) return;

        VelocoreLike pool = new VelocoreLike();
        pool.withdrawWithFee(amount, feeMultiplier);

        // Soundness: rebate (lpBalance - amount) must equal (feeMultiplier - 100),
        // which is only well-defined when feeMultiplier >= 100. Otherwise the
        // attacker should not be credited anything beyond `amount`.
        if (feeMultiplier < 100) {
            assert(pool.lpBalance(address(this)) <= amount);
        }
    }
}
