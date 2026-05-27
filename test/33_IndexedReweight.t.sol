// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IndexedLike} from "../src/33_IndexedReweight.sol";

contract IndexedReweightTest is Test {
    function checkReweightCannotZeroWeight(uint256 delta) public {
        if (delta == 0 || delta > 100) return;

        IndexedLike p = new IndexedLike();
        address t = address(0xABCD);
        p.init(t, 50, 1_000);

        p.reweight(t, delta);

        // Soundness: a single user-supplied delta must not drop weight to 0
        // without an explicit governance signal.
        assert(p.weight(t) > 0);
    }
}
