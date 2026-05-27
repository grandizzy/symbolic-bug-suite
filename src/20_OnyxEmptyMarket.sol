// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Onyx Protocol (Sep 2023, $2.1M). Same empty-market share inflation
/// class as Hundred (#06) and Sonne (#19).
contract OnyxVaultLike {
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
