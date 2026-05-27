// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MisoLike} from "../src/17_MisoSelectorConfusion.sol";

contract MisoSelectorConfusionTest is Test {
    function checkCreditNeverExceedsMsgValue(bool useMulticall) public payable {
        vm.deal(address(this), 1000 ether);
        MisoLike a = new MisoLike();

        if (useMulticall) {
            // Single ETH payment, doubled by repeating the sub-call.
            bytes[] memory calls = new bytes[](2);
            calls[0] = abi.encodeCall(a.commitEth, ());
            calls[1] = abi.encodeCall(a.commitEth, ());
            a.multicall{value: 1 ether}(calls);
        } else {
            a.commitEth{value: 1 ether}();
        }

        // Soundness: caller paid 1 ETH, so credit must be at most 1 ETH.
        assert(a.credit(address(this)) <= 1 ether);
    }
}
