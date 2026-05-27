// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {FurucomboLike} from "../src/32_FurucomboDelegatecall.sol";

contract HandlerStealer {
    address public handler;
    function pwn(address h) external {
        handler = h;
    }
}

contract FurucomboDelegatecallTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function checkHandlerNotHijackable(address attacker) public {
        FurucomboLike proxy = new FurucomboLike();
        HandlerStealer s = new HandlerStealer();

        // Legitimate setup: trusted handler is installed by deployer.
        address legitHandler = address(0xC0DE);
        proxy.setHandler(legitHandler);

        if (attacker == address(this) || attacker == address(0)) return;

        vm.prank(attacker);
        proxy.setHandler(address(s));
        vm.prank(attacker);
        proxy.exec(abi.encodeCall(HandlerStealer.pwn, (attacker)));

        // Soundness: the handler slot should not be reassignable by a third party.
        assert(proxy.handler() == legitHandler);
    }
}
