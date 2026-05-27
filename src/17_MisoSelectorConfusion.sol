// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice SushiSwap MISO `batchAuction` (Sep 2021, $3M attempted). The
/// auction contract had a `multicall` that delegated to itself, and a
/// `commitEth()` payable entrypoint. Because `msg.value` is preserved
/// across delegatecall, an attacker called `multicall` with N copies of
/// `commitEth()`, getting N×msg.value of credit for a single payment.
contract MisoLike {
    mapping(address => uint256) public credit;
    uint256 public totalCommitted;

    function commitEth() external payable {
        // Bug-prone pattern: trusts msg.value blindly inside delegatecall context.
        credit[msg.sender] += msg.value;
        totalCommitted += msg.value;
    }

    function multicall(bytes[] calldata calls) external payable returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool ok, bytes memory ret) = address(this).delegatecall(calls[i]);
            require(ok, "!sub");
            results[i] = ret;
        }
    }
}
