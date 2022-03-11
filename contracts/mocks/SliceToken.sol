// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/ISliceToken.sol";

contract SliceToken is OwnableUpgradeable, ERC20Upgradeable, ISliceToken {
    using SafeMathUpgradeable for uint256;

    uint256 private _SUPPLY_CAP;

    function initialize(uint256 _initialSupply, uint256 _cap) public initializer {
        OwnableUpgradeable.__Ownable_init();
        ERC20Upgradeable.__ERC20_init_unchained("SliceToken", "SLICE");
        _mint(msg.sender, _initialSupply.mul(uint(1e18)));
        _SUPPLY_CAP = _cap.mul(uint(1e18));
    }

    /**
     * @notice Mint LOOKS tokens
     * @param account address to receive tokens
     * @param amount amount to mint
     * @return status true if mint is successful, false if not
     */
    function mint(address account, uint256 amount) external override onlyOwner returns (bool status) {
        if (totalSupply() + amount <= _SUPPLY_CAP) {
            _mint(account, amount);
            return true;
        }
        return false;
    }

    /**
     * @notice View supply cap
     */
    function SUPPLY_CAP() external view override returns (uint256) {
        return _SUPPLY_CAP;
    }

}