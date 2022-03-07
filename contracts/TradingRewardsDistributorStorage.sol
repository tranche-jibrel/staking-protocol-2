// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract TradingRewardsDistributorStorage {
    uint256 public constant BUFFER_ADMIN_WITHDRAW = 3 days;

    IERC20Upgradeable public sliceToken;

    // Current reward round (users can only claim pending rewards for the current round)
    uint256 public currentRewardRound;

    // Last paused timestamp
    uint256 public lastPausedTimestamp;

    // Max amount per user in current tree
    uint256 public maximumAmountPerUserInCurrentTree;

    // Total amount claimed by user (in SLICE)
    mapping(address => uint256) public amountClaimedByUser;

    // Merkle root for a reward round
    mapping(uint256 => bytes32) public merkleRootOfRewardRound;

    // Checks whether a merkle root was used
    mapping(bytes32 => bool) public merkleRootUsed;

    // Keeps track on whether user has claimed at a given reward round
    mapping(uint256 => mapping(address => bool)) public hasUserClaimedForRewardRound;
}