// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILooksRareToken.sol";

contract TokenDistributorStorage {
    struct StakingPeriod {
        uint256 rewardPerBlockForStaking;
        uint256 rewardPerBlockForOthers;
        uint256 periodLengthInBlock;
    }

    struct UserInfo {
        uint256 amount; // Amount of staked tokens provided by user
        uint256 rewardDebt; // Reward debt
    }

    // Precision factor for calculating rewards
    uint256 public constant PRECISION_FACTOR = 10**12;

    ILooksRareToken public sliceToken;

    address public tokenSplitter;

    // Number of reward periods
    uint256 public NUMBER_PERIODS;

    // Block number when rewards start
    uint256 public START_BLOCK;

    // Accumulated tokens per share
    uint256 public accTokenPerShare;

    // Current phase for rewards
    uint256 public currentPhase;

    // Block number when rewards end
    uint256 public endBlock;

    // Block number of the last update
    uint256 public lastRewardBlock;

    // Tokens distributed per block for other purposes (team + treasury + trading rewards)
    uint256 public rewardPerBlockForOthers;

    // Tokens distributed per block for staking
    uint256 public rewardPerBlockForStaking;

    // Total amount staked
    uint256 public totalAmountStaked;

    mapping(uint256 => StakingPeriod) public stakingPeriod;

    mapping(address => UserInfo) public userInfo;
}