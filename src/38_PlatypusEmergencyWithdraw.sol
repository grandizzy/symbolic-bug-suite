// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Platypus Finance (Feb 2023, ~$8.5M). `emergencyWithdraw` checked
/// solvency before removing the LP collateral, then zeroed the user's position
/// without clearing debt. A borrower could leave with no collateral and live debt.
contract PlatypusLikeTreasure {
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;

    function addCollateral(address user, uint256 amount) external {
        collateral[user] += amount;
    }

    function removeCollateral(address user, uint256 amount) external {
        require(collateral[user] >= amount, "collateral");
        collateral[user] -= amount;
    }

    function borrow(uint256 amount) external {
        debt[msg.sender] += amount;
        require(isSolvent(msg.sender), "insolvent");
    }

    function isSolvent(address user) public view returns (bool) {
        // Keep the real dependency explicit: solvency is a collateral/debt
        // relation, not just a local MasterPlatypus balance check.
        return collateral[user] * 80 >= debt[user] * 100;
    }
}

contract PlatypusLikeMaster {
    struct UserInfo {
        uint256 amount;
    }

    PlatypusLikeTreasure public immutable treasure;
    mapping(address => UserInfo) public userInfo;

    constructor(PlatypusLikeTreasure _treasure) {
        treasure = _treasure;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "zero deposit");
        userInfo[msg.sender].amount += amount;
        treasure.addCollateral(msg.sender, amount);
    }

    function emergencyWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        require(amount > 0, "empty");

        // Bug: the check runs against the pre-withdraw collateral balance.
        require(treasure.isSolvent(msg.sender), "insolvent");

        user.amount = 0;
        treasure.removeCollateral(msg.sender, amount);
    }
}
