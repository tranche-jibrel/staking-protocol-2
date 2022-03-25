// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMultiRewards {
    /* ========== EVENTS ========== */
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
    event RewardsDurationUpdated(address token, uint256 newDuration);
    event Recovered(address token, uint256 amount);
    function notifyRewardAmount(address _rewardsToken, uint256 reward) external;
}