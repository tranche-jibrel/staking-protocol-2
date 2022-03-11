// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenSplitterStorage {
    event NewSharesOwner(address indexed oldRecipient, address indexed newRecipient);
    event TokensTransferred(address indexed account, uint256 amount);
}