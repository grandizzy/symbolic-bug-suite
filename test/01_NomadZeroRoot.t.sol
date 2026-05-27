// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {NomadLike} from "../src/01_NomadZeroRoot.sol";

contract NomadZeroRootTest is Test {
    function checkOnlyInstalledRootsAreAccepted(bytes32 root) public {
        NomadLike bridge = new NomadLike();
        // Never call update() — only an installed root should be accepted.
        bridge.process(root);
    }
}
