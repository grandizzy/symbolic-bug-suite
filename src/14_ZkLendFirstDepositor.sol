// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice zkLend (Feb 2025, $9.5M). First-depositor inflation via redemption
/// rounding: attacker deposits 1 share, then repeatedly redeems 1 wei to
/// inflate the share price through cumulative rounding bias, finally minting
/// shares cheaper than the underlying they're worth.
contract ZkLendVaultLike {
    uint256 public totalShares;
    uint256 public totalAssets;
    mapping(address => uint256) public shares;

    function deposit(uint256 assets) external returns (uint256 sharesOut) {
        sharesOut = totalShares == 0 ? assets : (assets * totalShares) / totalAssets;
        shares[msg.sender] += sharesOut;
        totalShares += sharesOut;
        totalAssets += assets;
    }

    /// Bug: redeem rounds the asset payout up (`+1`) as a safety bumper,
    /// but does not floor totalAssets accordingly; over many tiny redeems
    /// the share price drifts upward.
    function redeem(uint256 sharesIn) external returns (uint256 assetsOut) {
        assetsOut = (sharesIn * totalAssets) / totalShares + 1; // bug: +1
        shares[msg.sender] -= sharesIn;
        totalShares -= sharesIn;
        totalAssets -= assetsOut;
    }
}
