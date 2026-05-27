// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {QubitLike} from "../src/25_QubitZeroDeposit.sol";

contract QubitZeroDepositTest is Test {
    function checkNativeDepositRequiresMsgValue(uint256 amount) public {
        if (amount == 0 || amount > 1e30) return;

        QubitLike q = new QubitLike();
        // Caller forwards no msg.value but claims a native deposit.
        q.deposit(address(0), amount);

        // Soundness: zero-value native deposit must not credit any balance.
        assert(q.xBalance(address(this)) == 0);
    }
}
