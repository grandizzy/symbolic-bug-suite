// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LendfMeLike, ITokenReceiver} from "../src/31_LendfMeERC777.sol";

contract ERC777Attacker is ITokenReceiver {
    LendfMeLike public pool;
    bool entered;
    uint256 public stolen;

    function setPool(LendfMeLike p) external {
        pool = p;
    }

    function tokensReceived(address, address, uint256 amount) external override {
        if (!entered) {
            entered = true;
            try pool.borrow(amount) {
                stolen += amount;
            } catch {}
        }
    }
}

contract LendfMeERC777Test is Test {
    function checkCollateralCreditedBeforeAnyBorrow(uint256 amount) public {
        if (amount == 0 || amount > 1e30) return;

        LendfMeLike pool = new LendfMeLike();
        ERC777Attacker atk = new ERC777Attacker();
        atk.setPool(pool);

        vm.prank(address(atk));
        pool.deposit(address(atk), amount);

        // Soundness: the attacker should not have been able to borrow against
        // collateral that wasn't yet credited.
        assert(atk.stolen() == 0);
    }
}
