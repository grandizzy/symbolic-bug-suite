// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Parity multisig (Jul 2017, $150M+). The library's `initWallet`
/// function was callable by anyone after deployment, letting an attacker
/// reset the wallet owner.
contract ParityWalletLike {
    address public owner;
    bool public initialized;

    // Bug: no `initialized` guard, no `onlyOwner` check.
    function initWallet(address newOwner) external {
        owner = newOwner;
        initialized = true;
    }

    function setOwner(address newOwner) external {
        require(msg.sender == owner, "!owner");
        owner = newOwner;
    }
}
