// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {UraniumLikePair} from "../src/37_UraniumInvariant.sol";

contract UraniumInvariantTest is Test {
    function checkSwapCannotDrainPoolForDustInput(bool chooseDrainAmount) public {
        uint256 reserve0 = 10_000;
        uint256 reserve1 = 10_000;
        uint256 amount1Out = chooseDrainAmount ? 9_000 : 1;

        UraniumLikePair pair = new UraniumLikePair();
        pair.init(reserve0, reserve1);

        pair.swap(1, amount1Out);

        // Soundness: one unit of input cannot withdraw a material fraction of
        // the other reserve under the intended 10,000-denominator invariant.
        assert(amount1Out <= 100);
    }
}
