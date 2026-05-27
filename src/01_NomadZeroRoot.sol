// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Nomad bridge (Aug 2022, $190M). Buggy migration left the zero root
/// pre-confirmed, so any message whose computed merkle root happened to be 0
/// passed verification.
contract NomadLike {
    mapping(bytes32 => uint256) public confirmAt;
    bool public rootInstalled;

    constructor() {
        // The actual bug: zero root accepted without ever being installed.
        confirmAt[bytes32(0)] = 1;
    }

    function update(bytes32 root) external {
        confirmAt[root] = 1;
        rootInstalled = true;
    }

    function process(bytes32 root) external {
        require(confirmAt[root] != 0, "!proven");
        // Soundness invariant we expect to always hold.
        assert(rootInstalled);
    }
}
