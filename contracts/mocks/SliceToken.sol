// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SliceToken is OwnableUpgradeable, ERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    function initialize(uint256 _initialSupply) public initializer {
        OwnableUpgradeable.__Ownable_init();
        ERC20Upgradeable.__ERC20_init_unchained("SliceToken", "SLICE");
        _mint(msg.sender, _initialSupply.mul(uint(1e18)));
    }
}