// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice DODO (Mar 2021, $3.8M). The pool's `init` lacked a guard, letting
/// anyone re-initialize and become the pool admin or zero out reserves.
contract DODOLike {
    address public admin;
    uint256 public reserves;

    // Bug: no `initialized` flag.
    function init(address _admin, uint256 _reserves) external {
        admin = _admin;
        reserves = _reserves;
    }
}
