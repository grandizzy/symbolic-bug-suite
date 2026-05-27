// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {FuseCTokenLike, IToken} from "../src/29_FeiRariReentrancy.sol";

contract ReenterToken is IToken {
    FuseCTokenLike public market;
    bool entered;
    uint256 public reborrowed;

    function setMarket(FuseCTokenLike m) external {
        market = m;
    }

    function callback() external override {
        if (!entered) {
            entered = true;
            try market.borrow(1 ether) {
                reborrowed += 1 ether;
            } catch {}
        }
    }
}

contract FeiRariReentrancyTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function checkBorrowAccountingNotBypassable(bool dummy) public payable {
        dummy;
        vm.deal(address(this), 1000 ether);

        FuseCTokenLike market = new FuseCTokenLike();
        ReenterToken token = new ReenterToken();
        market.setUnderlying(address(token));
        token.setMarket(market);
        market.fund{value: 10 ether}();

        vm.prank(address(token));
        market.borrow(1 ether);

        // Soundness: total borrowed credited equals total cash debited.
        // If the reentry succeeded, borrowOf would only reflect 1 ether but
        // cash dropped by 2 ether — provable here via reborrowed counter.
        assert(token.reborrowed() == 0);
    }
}
