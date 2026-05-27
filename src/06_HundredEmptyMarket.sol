// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Hundred Finance (Apr 2023, $7M) / Sonne (May 2024, $20M) / many
/// other Compound-v2 forks. Empty-market share inflation: attacker deposits
/// 1 wei, donates underlying directly to the contract to inflate the share
/// price, then victim deposits round-down to 0 shares.
contract VaultLike {
    uint256 public totalShares;
    uint256 public totalUnderlying;
    mapping(address => uint256) public shares;

    function deposit(uint256 amount) external returns (uint256 sharesOut) {
        sharesOut = totalShares == 0 ? amount : (amount * totalShares) / totalUnderlying;
        shares[msg.sender] += sharesOut;
        totalShares += sharesOut;
        totalUnderlying += amount;
    }

    /// Anyone can donate underlying directly (or send via ERC20 transfer).
    function donate(uint256 amount) external {
        totalUnderlying += amount;
    }

    function redeem(uint256 sharesIn) external returns (uint256 amount) {
        amount = (sharesIn * totalUnderlying) / totalShares;
        shares[msg.sender] -= sharesIn;
        totalShares -= sharesIn;
        totalUnderlying -= amount;
    }
}
