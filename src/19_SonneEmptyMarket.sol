// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Sonne Finance (May 2024, $20M). Same empty-market share inflation
/// class as Hundred (#06) — included because the same one-line invariant
/// would have caught it 13 months later.
contract SonneVaultLike {
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
