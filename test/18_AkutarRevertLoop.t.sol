// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AuctionLike} from "../src/18_AkutarRevertLoop.sol";

/// A contract whose `receive` always reverts — models a malicious bidder.
contract RevertingBidder {
    receive() external payable {
        revert("nope");
    }
}

contract AkutarRevertLoopTest is Test {
    function checkRefundLoopReachesCompletion(bool includeReverter) public payable {
        vm.deal(address(this), 1000 ether);

        AuctionLike auction = new AuctionLike();
        address legit = address(0xBEEF);
        auction.bid{value: 1 ether}(legit);

        if (includeReverter) {
            RevertingBidder r = new RevertingBidder();
            auction.bid{value: 1 ether}(address(r));
        }

        // Soundness: processRefunds must always be able to finish.
        try auction.processRefunds() {
            assert(auction.refunded());
        } catch {
            assert(false);
        }
    }
}
