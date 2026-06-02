// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PlatypusLikeMaster, PlatypusLikeTreasure} from "../src/38_PlatypusEmergencyWithdraw.sol";

contract PlatypusEmergencyWithdrawTest is Test {
    function checkEmergencyWithdrawCannotLeaveUnbackedDebt(uint16 borrowAmount) public {
        uint256 collateral = 1_000;
        if (borrowAmount == 0 || borrowAmount > (collateral * 80) / 100) return;

        PlatypusLikeTreasure treasure = new PlatypusLikeTreasure();
        PlatypusLikeMaster master = new PlatypusLikeMaster(treasure);

        master.deposit(collateral);
        treasure.borrow(borrowAmount);
        master.emergencyWithdraw();

        // Soundness: a collateral-withdrawal path must not leave positive debt
        // with no collateral backing it.
        assert(treasure.debt(address(this)) == 0);
    }
}
