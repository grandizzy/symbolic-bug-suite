// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice The DAO (Jun 2016, $60M). The canonical reentrancy: `withdraw`
/// sent ETH before zeroing the depositor's balance.
contract DAOLike {
    mapping(address => uint256) public balanceOf;

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // Bug: state update after external call.
    function withdraw() external {
        uint256 amount = balanceOf[msg.sender];
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "!send");
        balanceOf[msg.sender] = 0;
    }
}
