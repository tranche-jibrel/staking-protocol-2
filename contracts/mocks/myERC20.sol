// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract myERC20 is Ownable, ERC20 {
    using SafeMath for uint256;

    constructor(uint256 _initialSupply) ERC20("RewardToken", "REW") {
        _mint(msg.sender, _initialSupply.mul(uint(1e18)));
    }

}