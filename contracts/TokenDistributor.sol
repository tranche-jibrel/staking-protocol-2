// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./TokenDistributorStorage.sol";
import {ISliceToken} from "./interfaces/ISliceToken.sol";
import {ITokenDistributor} from "./interfaces/ITokenDistributor.sol";

/**
 * @title TokenDistributor
 * @notice It handles the distribution of SLICE token.
 * It auto-adjusts block rewards over a set number of periods.
 */
contract TokenDistributor is ReentrancyGuardUpgradeable, TokenDistributorStorage, ITokenDistributor {
    // using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for ISliceToken;

    /**
     * @notice Constructor
     * @param _sliceToken SLICE token address
     * @param _tokenSplitter token splitter contract address (for team and trading rewards)
     * @param _startBlock start block for reward program
     * @param _rewardsPerBlockForStaking array of rewards per block for staking
     * @param _rewardsPerBlockForOthers array of rewards per block for other purposes (team + treasury + trading rewards)
     * @param _periodLengthesInBlocks array of period lengthes
     * @param _numberPeriods number of periods with different rewards/lengthes (e.g., if 3 changes --> 4 periods)
     */
    function initialize (address _sliceToken,
            address _tokenSplitter,
            uint256 _startBlock,
            uint256[] memory _rewardsPerBlockForStaking,
            uint256[] memory _rewardsPerBlockForOthers,
            uint256[] memory _periodLengthesInBlocks,
            uint256 _numberPeriods) public initializer {
        // OwnableUpgradeable.__Ownable_init();
        require(
            (_periodLengthesInBlocks.length == _numberPeriods) &&
                (_rewardsPerBlockForStaking.length == _numberPeriods) &&
                (_rewardsPerBlockForStaking.length == _numberPeriods),
            "Distributor: Lengthes must match numberPeriods"
        );
/*
        // 1. Operational checks for supply
        uint256 nonCirculatingSupply = ISliceToken(_sliceToken).SUPPLY_CAP() -
            ISliceToken(_sliceToken).totalSupply();

        uint256 amountTokensToBeMinted;
*/
        for (uint256 i = 0; i < _numberPeriods; i++) {
            /*amountTokensToBeMinted +=
                (_rewardsPerBlockForStaking[i] * _periodLengthesInBlocks[i]) +
                (_rewardsPerBlockForOthers[i] * _periodLengthesInBlocks[i]);
            */
            stakingPeriod[i] = StakingPeriod({
                rewardPerBlockForStaking: _rewardsPerBlockForStaking[i],
                rewardPerBlockForOthers: _rewardsPerBlockForOthers[i],
                periodLengthInBlock: _periodLengthesInBlocks[i]
            });
        }

        // require(amountTokensToBeMinted == nonCirculatingSupply, "Distributor: Wrong reward parameters");

        // 2. Store values
        sliceToken = ISliceToken(_sliceToken);
        tokenSplitter = _tokenSplitter;
        rewardPerBlockForStaking = _rewardsPerBlockForStaking[0];
        rewardPerBlockForOthers = _rewardsPerBlockForOthers[0];

        START_BLOCK = _startBlock;
        endBlock = _startBlock + _periodLengthesInBlocks[0];

        NUMBER_PERIODS = _numberPeriods;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = _startBlock;
    }

    /**
     * @notice Deposit staked tokens and compounds pending rewards
     * @param amount amount to deposit (in SLICE)
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit: Amount must be > 0");

        // Update pool information
        _updatePool();

        // Transfer SLICE tokens to this contract
        sliceToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 pendingRewards;

        // If not new deposit, calculate pending rewards (for auto-compounding)
        if (userInfo[msg.sender].amount > 0) {
            pendingRewards =
                ((userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR) -
                userInfo[msg.sender].rewardDebt;
        }

        // Adjust user information
        userInfo[msg.sender].amount += (amount + pendingRewards);
        userInfo[msg.sender].rewardDebt = (userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR;

        // Increase totalAmountStaked
        totalAmountStaked += (amount + pendingRewards);

        emit Deposit(msg.sender, amount, pendingRewards);
    }

    /**
     * @notice Compound based on pending rewards
     */
    function harvestAndCompound() external nonReentrant {
        // Update pool information
        _updatePool();

        // Calculate pending rewards
        uint256 pendingRewards = ((userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR) -
            userInfo[msg.sender].rewardDebt;

        // Return if no pending rewards
        if (pendingRewards == 0) {
            // It doesn't throw revertion (to help with the fee-sharing auto-compounding contract)
            return;
        }

        // Adjust user amount for pending rewards
        userInfo[msg.sender].amount += pendingRewards;

        // Adjust totalAmountStaked
        totalAmountStaked += pendingRewards;

        // Recalculate reward debt based on new user amount
        userInfo[msg.sender].rewardDebt = (userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR;

        emit Compound(msg.sender, pendingRewards);
    }

    /**
     * @notice Update pool rewards
     */
    function updatePool() external nonReentrant {
        _updatePool();
    }

    /**
     * @notice Withdraw staked tokens and compound pending rewards
     * @param amount amount to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(
            (userInfo[msg.sender].amount >= amount) && (amount > 0),
            "Withdraw: Amount must be > 0 or lower than user balance"
        );

        // Update pool
        _updatePool();

        // Calculate pending rewards
        uint256 pendingRewards = ((userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR) -
            userInfo[msg.sender].rewardDebt;

        // Adjust user information
        userInfo[msg.sender].amount = userInfo[msg.sender].amount + pendingRewards - amount;
        userInfo[msg.sender].rewardDebt = (userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR;

        // Adjust total amount staked
        totalAmountStaked = totalAmountStaked + pendingRewards - amount;

        // Transfer SLICE tokens to the sender
        sliceToken.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount, pendingRewards);
    }

    /**
     * @notice Withdraw all staked tokens and collect tokens
     */
    function withdrawAll() external nonReentrant {
        require(userInfo[msg.sender].amount > 0, "Withdraw: Amount must be > 0");

        // Update pool
        _updatePool();

        // Calculate pending rewards and amount to transfer (to the sender)
        uint256 pendingRewards = ((userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR) -
            userInfo[msg.sender].rewardDebt;

        uint256 amountToTransfer = userInfo[msg.sender].amount + pendingRewards;

        // Adjust total amount staked
        totalAmountStaked = totalAmountStaked - userInfo[msg.sender].amount;

        // Adjust user information
        userInfo[msg.sender].amount = 0;
        userInfo[msg.sender].rewardDebt = 0;

        // Transfer SLICE tokens to the sender
        sliceToken.safeTransfer(msg.sender, amountToTransfer);

        emit Withdraw(msg.sender, amountToTransfer, pendingRewards);
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user address of the user
     * @return Pending rewards
     */
    function calculatePendingRewards(address user) external view returns (uint256) {
        if ((block.number > lastRewardBlock) && (totalAmountStaked != 0)) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);

            uint256 tokenRewardForStaking = multiplier * rewardPerBlockForStaking;

            uint256 adjustedEndBlock = endBlock;
            uint256 adjustedCurrentPhase = currentPhase;

            // Check whether to adjust multipliers and reward per block
            while ((block.number > adjustedEndBlock) && (adjustedCurrentPhase < (NUMBER_PERIODS - 1))) {
                // Update current phase
                adjustedCurrentPhase++;

                // Update rewards per block
                uint256 adjustedRewardPerBlockForStaking = stakingPeriod[adjustedCurrentPhase].rewardPerBlockForStaking;

                // Calculate adjusted block number
                uint256 previousEndBlock = adjustedEndBlock;

                // Update end block
                adjustedEndBlock = previousEndBlock + stakingPeriod[adjustedCurrentPhase].periodLengthInBlock;

                // Calculate new multiplier
                uint256 newMultiplier = (block.number <= adjustedEndBlock)
                    ? (block.number - previousEndBlock)
                    : stakingPeriod[adjustedCurrentPhase].periodLengthInBlock;

                // Adjust token rewards for staking
                tokenRewardForStaking += (newMultiplier * adjustedRewardPerBlockForStaking);
            }

            uint256 adjustedTokenPerShare = accTokenPerShare +
                (tokenRewardForStaking * PRECISION_FACTOR) /
                totalAmountStaked;

            return (userInfo[user].amount * adjustedTokenPerShare) / PRECISION_FACTOR - userInfo[user].rewardDebt;
        } else {
            return (userInfo[user].amount * accTokenPerShare) / PRECISION_FACTOR - userInfo[user].rewardDebt;
        }
    }

    /**
     * @notice Update reward variables of the pool
     */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalAmountStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }

        // Calculate multiplier
        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);

        // Calculate rewards for staking and others
        uint256 tokenRewardForStaking = multiplier * rewardPerBlockForStaking;
        uint256 tokenRewardForOthers = multiplier * rewardPerBlockForOthers;

        // Check whether to adjust multipliers and reward per block
        while ((block.number > endBlock) && (currentPhase < (NUMBER_PERIODS - 1))) {
            // Update rewards per block
            _updateRewardsPerBlock(endBlock);

            uint256 previousEndBlock = endBlock;

            // Adjust the end block
            endBlock += stakingPeriod[currentPhase].periodLengthInBlock;

            // Adjust multiplier to cover the missing periods with other lower inflation schedule
            uint256 newMultiplier = _getMultiplier(previousEndBlock, block.number);

            // Adjust token rewards
            tokenRewardForStaking += (newMultiplier * rewardPerBlockForStaking);
            tokenRewardForOthers += (newMultiplier * rewardPerBlockForOthers);
        }

        // Mint tokens only if token rewards for staking are not null
        if (tokenRewardForStaking > 0) {
            // It allows protection against potential issues to prevent funds from being locked
            bool mintStatus = sliceToken.mint(address(this), tokenRewardForStaking);
            if (mintStatus) {
                accTokenPerShare = accTokenPerShare + ((tokenRewardForStaking * PRECISION_FACTOR) / totalAmountStaked);
            }

            sliceToken.mint(tokenSplitter, tokenRewardForOthers);
        }

        // Update last reward block only if it wasn't updated after or at the end block
        if (lastRewardBlock <= endBlock) {
            lastRewardBlock = block.number;
        }
    }

    /**
     * @notice Update rewards per block
     * @dev Rewards are halved by 2 (for staking + others)
     */
    function _updateRewardsPerBlock(uint256 _newStartBlock) internal {
        // Update current phase
        currentPhase++;

        // Update rewards per block
        rewardPerBlockForStaking = stakingPeriod[currentPhase].rewardPerBlockForStaking;
        rewardPerBlockForOthers = stakingPeriod[currentPhase].rewardPerBlockForOthers;

        emit NewRewardsPerBlock(currentPhase, _newStartBlock, rewardPerBlockForStaking, rewardPerBlockForOthers);
    }

    /**
     * @notice Return reward multiplier over the given "from" to "to" block.
     * @param from block to start calculating reward
     * @param to block to finish calculating reward
     * @return the multiplier for the period
     */
    function _getMultiplier(uint256 from, uint256 to) internal view returns (uint256) {
        if (to <= endBlock) {
            return to - from;
        } else if (from >= endBlock) {
            return 0;
        } else {
            return endBlock - from;
        }
    }
}
