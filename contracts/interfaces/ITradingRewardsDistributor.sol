// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITradingRewardsDistributor {
    /* ========== EVENTS ========== */
    event RewardsClaim(address indexed user, uint256 indexed rewardRound, uint256 amount);
    event UpdateTradingRewards(uint256 indexed rewardRound);
    event TokenWithdrawnOwner(uint256 amount);
}