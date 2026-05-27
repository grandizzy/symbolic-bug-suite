// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MonoXLike} from "../src/23_MonoXSameToken.sol";

contract MonoXSameTokenTest is Test {
    function checkSwapOutputCannotExceedInputForSelfSwap(uint256 amountIn) public {
        if (amountIn == 0 || amountIn > 1_000) return;

        MonoXLike pool = new MonoXLike();
        address token = address(0xABCD);
        pool.init(token, 1_000_000, 1e18);

        uint256 out = pool.swap(token, token, amountIn);

        // Soundness: swapping a token for itself should yield at most what you put in.
        assert(out <= amountIn);
    }
}
