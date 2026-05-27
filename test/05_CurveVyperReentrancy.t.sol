// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CurvePoolLike} from "../src/05_CurveVyperReentrancy.sol";

contract ReentrantAttacker {
    CurvePoolLike public pool;
    bool entered;
    uint256 public depositAmount;

    constructor(CurvePoolLike _pool) {
        pool = _pool;
    }

    function attack(uint256 amount) external {
        depositAmount = amount;
        pool.addLiquidity{value: amount}();
        pool.removeLiquidity(amount);
    }

    receive() external payable {
        if (!entered && address(pool).balance >= depositAmount) {
            entered = true;
            pool.removeLiquidity(depositAmount);
        }
    }
}

contract CurveVyperReentrancyTest is Test {
    function checkLpCannotWithdrawMoreThanDeposited(uint256 attackerDeposit) public payable {
        if (attackerDeposit == 0 || attackerDeposit > 100 ether) return;

        // Concrete balances for the test driver and the attacker contract.
        vm.deal(address(this), 1000 ether);

        CurvePoolLike pool = new CurvePoolLike();
        // Seed pool with other LP liquidity so the attacker can drain extra.
        pool.addLiquidity{value: 100 ether}();

        ReentrantAttacker atk = new ReentrantAttacker(pool);
        vm.deal(address(atk), 100 ether);
        atk.attack(attackerDeposit);

        // Soundness: the attacker should not finish with more native balance
        // than they put in.
        assert(address(atk).balance <= attackerDeposit);
    }
}
