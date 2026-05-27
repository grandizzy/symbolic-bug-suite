// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Euler Finance (Mar 2023, $197M). `donateToReserves` reduced the
/// donor's eToken balance without recomputing health, letting a borrower
/// donate themselves into an unhealthy state on purpose and then immediately
/// self-liquidate, capturing the discount.
contract EulerLike {
    mapping(address => uint256) public eTokenBal;   // collateral
    mapping(address => uint256) public dTokenBal;   // debt
    uint256 public reserves;

    function deposit(uint256 amount) external {
        eTokenBal[msg.sender] += amount;
    }

    function borrow(uint256 amount) external {
        dTokenBal[msg.sender] += amount;
        require(_healthy(msg.sender), "!healthy");
    }

    // Bug: skips health check after debiting collateral.
    function donateToReserves(uint256 amount) external {
        require(eTokenBal[msg.sender] >= amount);
        eTokenBal[msg.sender] -= amount;
        reserves += amount;
    }

    function liquidate(address victim) external returns (uint256 seized) {
        require(!_healthy(victim), "healthy");
        // Liquidator seizes 1.1x the debt as collateral (10% discount).
        uint256 discount = (dTokenBal[victim] * 11) / 10;
        seized = discount > eTokenBal[victim] ? eTokenBal[victim] : discount;
        eTokenBal[victim] -= seized;
        dTokenBal[victim] = 0;
        eTokenBal[msg.sender] += seized;
    }

    function _healthy(address who) internal view returns (bool) {
        return eTokenBal[who] >= dTokenBal[who];
    }
}
