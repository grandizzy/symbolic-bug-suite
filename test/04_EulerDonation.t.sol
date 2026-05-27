// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {EulerLike} from "../src/04_EulerDonation.sol";

contract EulerDonationTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function checkDonationDoesNotEnableProfit(uint256 donate) public {
        // Hold setup concrete; only the attacker-controlled `donate` is symbolic.
        // The historical exploit shape: make oneself unhealthy then have a
        // sibling account liquidate, capturing the 10% discount.
        uint256 collateral = 200;
        uint256 borrow = 150;
        if (donate > collateral) return;

        EulerLike pool = new EulerLike();
        address attacker = address(this);
        address shadow = address(0xBEEF);

        pool.deposit(collateral);
        pool.borrow(borrow);
        pool.donateToReserves(donate);

        vm.prank(shadow);
        pool.liquidate(attacker);

        // Soundness: attacker cannot extract more than initially deposited.
        uint256 extracted = borrow + pool.eTokenBal(shadow);
        assert(extracted <= collateral);
    }
}
