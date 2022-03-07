// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import"./FeeSharingSystemStorage.sol";
import"./interfaces/IFeeSharingSystem.sol";

/**
 * @title FeeSharingSystem
 * @notice It handles the distribution of fees using
 * WETH along with the auto-compounding of SLICE.
 */
contract FeeSharingSystem is ReentrancyGuardUpgradeable, OwnableUpgradeable, FeeSharingSystemStorage, IFeeSharingSystem {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Constructor
     * @param _sliceToken address of the token staked (SLICE)
     * @param _rewardToken address of the reward token
     * @param _tokenDistributor address of the token distributor contract
     */
    function initialize (address _sliceToken,
            address _rewardToken,
            address _tokenDistributor) public initializer {
        OwnableUpgradeable.__Ownable_init();
        rewardToken = IERC20Upgradeable(_rewardToken);
        sliceToken = IERC20Upgradeable(_sliceToken);
        tokenDistributor = TokenDistributor(_tokenDistributor);
    }

    /**
     * @notice Deposit staked tokens (and collect reward tokens if requested)
     * @param amount amount to deposit (in SLICE)
     * @param claimRewardToken whether to claim reward tokens
     * @dev There is a limit of 1 SLICE per deposit to prevent potential manipulation of current shares
     */
    function deposit(uint256 amount, bool claimRewardToken) external nonReentrant {
        require(amount >= PRECISION_FACTOR, "Deposit: Amount must be >= 1 SLICE");

        // Auto compounds for everyone
        tokenDistributor.harvestAndCompound();

        // Update reward for user
        _updateReward(msg.sender);

        // Retrieve total amount staked by this contract
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));

        // Transfer SLICE tokens to this address
        sliceToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 currentShares;

        // Calculate the number of shares to issue for the user
        if (totalShares != 0) {
            currentShares = (amount * totalShares) / totalAmountStaked;
            // This is a sanity check to prevent deposit for 0 shares
            require(currentShares != 0, "Deposit: Fail");
        } else {
            currentShares = amount;
        }

        // Adjust internal shares
        userInfo[msg.sender].shares += currentShares;
        totalShares += currentShares;

        uint256 pendingRewards;

        if (claimRewardToken) {
            // Fetch pending rewards
            pendingRewards = userInfo[msg.sender].rewards;

            if (pendingRewards > 0) {
                userInfo[msg.sender].rewards = 0;
                rewardToken.safeTransfer(msg.sender, pendingRewards);
            }
        }

        // Verify SLICE token allowance and adjust if necessary
        _checkAndAdjustSLICETokenAllowanceIfRequired(amount, address(tokenDistributor));

        // Deposit user amount in the token distributor contract
        tokenDistributor.deposit(amount);

        emit Deposit(msg.sender, amount, pendingRewards);
    }

    /**
     * @notice Harvest reward tokens that are pending
     */
    function harvest() external nonReentrant {
        // Auto compounds for everyone
        tokenDistributor.harvestAndCompound();

        // Update reward for user
        _updateReward(msg.sender);

        // Retrieve pending rewards
        uint256 pendingRewards = userInfo[msg.sender].rewards;

        // If pending rewards are null, revert
        require(pendingRewards > 0, "Harvest: Pending rewards must be > 0");

        // Adjust user rewards and transfer
        userInfo[msg.sender].rewards = 0;

        // Transfer reward token to sender
        rewardToken.safeTransfer(msg.sender, pendingRewards);

        emit Harvest(msg.sender, pendingRewards);
    }

    /**
     * @notice Withdraw staked tokens (and collect reward tokens if requested)
     * @param shares shares to withdraw
     * @param claimRewardToken whether to claim reward tokens
     */
    function withdraw(uint256 shares, bool claimRewardToken) external nonReentrant {
        require(
            (shares > 0) && (shares <= userInfo[msg.sender].shares),
            "Withdraw: Shares equal to 0 or larger than user shares"
        );

        _withdraw(shares, claimRewardToken);
    }

    /**
     * @notice Withdraw all staked tokens (and collect reward tokens if requested)
     * @param claimRewardToken whether to claim reward tokens
     */
    function withdrawAll(bool claimRewardToken) external nonReentrant {
        _withdraw(userInfo[msg.sender].shares, claimRewardToken);
    }

    /**
     * @notice Update the reward per block (in rewardToken)
     * @dev Only callable by owner. Owner is meant to be another smart contract.
     */
    function updateRewards(uint256 reward, uint256 rewardDurationInBlocks) external onlyOwner {
        // Adjust the current reward per block
        if (block.number >= periodEndBlock) {
            currentRewardPerBlock = reward / rewardDurationInBlocks;
        } else {
            currentRewardPerBlock =
                (reward + ((periodEndBlock - block.number) * currentRewardPerBlock)) /
                rewardDurationInBlocks;
        }

        lastUpdateBlock = block.number;
        periodEndBlock = block.number + rewardDurationInBlocks;

        emit NewRewardPeriod(rewardDurationInBlocks, currentRewardPerBlock, reward);
    }

    /**
     * @notice Calculate pending rewards (WETH) for a user
     * @param user address of the user
     */
    function calculatePendingRewards(address user) external view returns (uint256) {
        return _calculatePendingRewards(user);
    }

    /**
     * @notice Calculate value of SLICE for a user given a number of shares owned
     * @param user address of the user
     */
    function calculateSharesValueInSLICE(address user) external view returns (uint256) {
        // Retrieve amount staked
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));

        // Adjust for pending rewards
        totalAmountStaked += tokenDistributor.calculatePendingRewards(address(this));

        // Return user pro-rata of total shares
        return userInfo[user].shares == 0 ? 0 : (totalAmountStaked * userInfo[user].shares) / totalShares;
    }

    /**
     * @notice Calculate price of one share (in SLICE token)
     * Share price is expressed times 1e18
     */
    function calculateSharePriceInSLICE() external view returns (uint256) {
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));

        // Adjust for pending rewards
        totalAmountStaked += tokenDistributor.calculatePendingRewards(address(this));

        return totalShares == 0 ? PRECISION_FACTOR : (totalAmountStaked * PRECISION_FACTOR) / (totalShares);
    }

    /**
     * @notice Return last block where trading rewards were distributed
     */
    function lastRewardBlock() external view returns (uint256) {
        return _lastRewardBlock();
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user address of the user
     */
    function _calculatePendingRewards(address user) internal view returns (uint256) {
        return
            ((userInfo[user].shares * (_rewardPerToken() - (userInfo[user].userRewardPerTokenPaid))) /
                PRECISION_FACTOR) + userInfo[user].rewards;
    }

    /**
     * @notice Check current allowance and adjust if necessary
     * @param _amount amount to transfer
     * @param _to token to transfer
     */
    function _checkAndAdjustSLICETokenAllowanceIfRequired(uint256 _amount, address _to) internal {
        if (sliceToken.allowance(address(this), _to) < _amount) {
            sliceToken.approve(_to, type(uint256).max);
        }
    }

    /**
     * @notice Return last block where rewards must be distributed
     */
    function _lastRewardBlock() internal view returns (uint256) {
        return block.number < periodEndBlock ? block.number : periodEndBlock;
    }

    /**
     * @notice Return reward per token
     */
    function _rewardPerToken() internal view returns (uint256) {
        if (totalShares == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((_lastRewardBlock() - lastUpdateBlock) * (currentRewardPerBlock * PRECISION_FACTOR)) /
            totalShares;
    }

    /**
     * @notice Update reward for a user account
     * @param _user address of the user
     */
    function _updateReward(address _user) internal {
        if (block.number != lastUpdateBlock) {
            rewardPerTokenStored = _rewardPerToken();
            lastUpdateBlock = _lastRewardBlock();
        }

        userInfo[_user].rewards = _calculatePendingRewards(_user);
        userInfo[_user].userRewardPerTokenPaid = rewardPerTokenStored;
    }

    /**
     * @notice Withdraw staked tokens (and collect reward tokens if requested)
     * @param shares shares to withdraw
     * @param claimRewardToken whether to claim reward tokens
     */
    function _withdraw(uint256 shares, bool claimRewardToken) internal {
        // Auto compounds for everyone
        tokenDistributor.harvestAndCompound();

        // Update reward for user
        _updateReward(msg.sender);

        // Retrieve total amount staked and calculated current amount (in SLICE)
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));
        uint256 currentAmount = (totalAmountStaked * shares) / totalShares;

        userInfo[msg.sender].shares -= shares;
        totalShares -= shares;

        // Withdraw amount equivalent in shares
        tokenDistributor.withdraw(currentAmount);

        uint256 pendingRewards;

        if (claimRewardToken) {
            // Fetch pending rewards
            pendingRewards = userInfo[msg.sender].rewards;

            if (pendingRewards > 0) {
                userInfo[msg.sender].rewards = 0;
                rewardToken.safeTransfer(msg.sender, pendingRewards);
            }
        }

        // Transfer SLICE tokens to sender
        sliceToken.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount, pendingRewards);
    }
}
