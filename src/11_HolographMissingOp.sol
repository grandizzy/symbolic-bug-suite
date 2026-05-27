// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Holograph (Jun 2024, $14.4M). The bridge endpoint `bridgeIn` was
/// missing its `onlyOperator` modifier, so any caller could mint tokens
/// directly to themselves by impersonating an inbound message.
contract HolographLike {
    address public operator;
    mapping(address => uint256) public balanceOf;

    constructor(address _operator) {
        operator = _operator;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "!operator");
        _;
    }

    // Bug: missing `onlyOperator` modifier.
    function bridgeIn(address to, uint256 amount) external /* onlyOperator */ {
        balanceOf[to] += amount;
    }
}
