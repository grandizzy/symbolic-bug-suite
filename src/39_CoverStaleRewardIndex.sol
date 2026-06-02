// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Cover Protocol Blacksmith (Dec 2020, multi-million COVER mint). The
/// reward-accounting path copied pool data to memory, updated storage, then used
/// the stale memory copy to compute a user's reward writeoff. New stake could
/// claim rewards that accrued before it existed.
contract CoverLikeBlacksmith {
    uint256 internal constant ACC_REWARD_PRECISION = 1000;

    struct PoolInfo {
        uint256 accRewardsPerToken;
        uint256 totalDeposits;
        uint256 queuedRewards;
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardWriteoff;
    }

    PoolInfo public pool;
    mapping(address => UserInfo) public userInfo;
    mapping(address => uint256) public mintedRewards;

    function deposit(uint256 amount) external {
        require(amount > 0, "zero deposit");

        // Bug shape: memory copy is taken before `updatePool`, then reused for
        // reward writeoff after storage `accRewardsPerToken` has changed.
        PoolInfo memory cachedPool = pool;
        updatePool();

        UserInfo storage user = userInfo[msg.sender];
        user.amount += amount;
        pool.totalDeposits += amount;
        user.rewardWriteoff = (user.amount * cachedPool.accRewardsPerToken) / ACC_REWARD_PRECISION;
    }

    function withdraw(uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= amount, "balance");

        updatePool();
        user.amount -= amount;
        pool.totalDeposits -= amount;
        user.rewardWriteoff = (user.amount * pool.accRewardsPerToken) / ACC_REWARD_PRECISION;
    }

    function queueRewards(uint256 amount) external {
        pool.queuedRewards += amount;
    }

    function claimRewards() external returns (uint256 pending) {
        updatePool();
        UserInfo storage user = userInfo[msg.sender];
        uint256 accumulated = (user.amount * pool.accRewardsPerToken) / ACC_REWARD_PRECISION;
        pending = accumulated - user.rewardWriteoff;
        user.rewardWriteoff = accumulated;
        mintedRewards[msg.sender] += pending;
    }

    function updatePool() public {
        if (pool.queuedRewards == 0 || pool.totalDeposits == 0) return;

        pool.accRewardsPerToken += (pool.queuedRewards * ACC_REWARD_PRECISION) / pool.totalDeposits;
        pool.queuedRewards = 0;
    }
}
