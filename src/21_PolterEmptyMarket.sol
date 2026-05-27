// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Polter Finance (Q1 2025, ~$700K). The class still ships in 2025:
/// yet another Compound-v2 fork hit by the same empty-market exploit as
/// Hundred (#06), Sonne (#19), and Onyx (#20).
contract PolterVaultLike {
    uint256 public totalShares;
    uint256 public totalUnderlying;
    mapping(address => uint256) public shares;

    function deposit(uint256 amount) external returns (uint256 sharesOut) {
        sharesOut = totalShares == 0 ? amount : (amount * totalShares) / totalUnderlying;
        shares[msg.sender] += sharesOut;
        totalShares += sharesOut;
        totalUnderlying += amount;
    }

    function donate(uint256 amount) external {
        totalUnderlying += amount;
    }
}
