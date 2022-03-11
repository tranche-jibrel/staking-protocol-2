// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ISliceToken is IERC20Upgradeable {
    function SUPPLY_CAP() external view returns (uint256);
    function mint(address account, uint256 amount) external returns (bool);
}
