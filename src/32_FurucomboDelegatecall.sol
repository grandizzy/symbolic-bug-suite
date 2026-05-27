// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Furucombo (Feb 2021, $14M). The proxy's `exec` delegatecall'd
/// into an uninitialized handler contract; the attacker initialized it
/// first with their own implementation, then triggered exec to delegate
/// into attacker-controlled code, draining users' approved tokens.
contract FurucomboLike {
    address public handler;

    // Bug: anyone can register a handler.
    function setHandler(address h) external {
        handler = h;
    }

    function exec(bytes calldata data) external returns (bytes memory) {
        (bool ok, bytes memory ret) = handler.delegatecall(data);
        require(ok, "!exec");
        return ret;
    }
}
