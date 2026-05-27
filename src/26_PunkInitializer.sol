// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Punk Protocol (Aug 2021, $3M). The `__init` function was left
/// public on the implementation contract and could be called post-deploy
/// to seize ownership and drain funds.
contract PunkLike {
    address public owner;

    // Bug: no initializer guard.
    function __init(address _owner) external {
        owner = _owner;
    }
}
