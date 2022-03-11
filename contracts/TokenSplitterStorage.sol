// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract TokenSplitterStorage {

    struct AccountInfo {
        uint256 shares;
        uint256 tokensDistributedToAccount;
    }

    uint256 public TOTAL_SHARES;

    IERC20Upgradeable public looksRareToken;

    // Total LOOKS tokens distributed across all accounts
    uint256 public totalTokensDistributed;

    mapping(address => AccountInfo) public accountInfo;
}