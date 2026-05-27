// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ZkLendVaultLike} from "../src/14_ZkLendFirstDepositor.sol";

contract ZkLendFirstDepositorTest {
    function checkRedeemNeverYieldsMoreThanFair(uint256 deposit) public {
        if (deposit == 0 || deposit > 1_000) return;

        ZkLendVaultLike vault = new ZkLendVaultLike();
        vault.deposit(deposit);

        // At 1:1 exchange rate, redeeming 1 share must yield at most 1 asset.
        uint256 out = vault.redeem(1);
        assert(out <= 1);
    }
}
