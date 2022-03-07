// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeSharingSystem {
    /* ========== EVENTS ========== */
    event Deposit(address indexed user, uint256 amount, uint256 harvestedAmount);
    event Harvest(address indexed user, uint256 harvestedAmount);
    event NewRewardPeriod(uint256 numberBlocks, uint256 rewardPerBlock, uint256 reward);
    event Withdraw(address indexed user, uint256 amount, uint256 harvestedAmount);
}