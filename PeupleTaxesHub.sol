// SPDX-License-Identifier: MIT

// WE ARE LE PEUPLE
// Peuple's Taxes Hub is redistributing fees to different services : like Bank, Marketing and Staking.

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IPeupleStaking.sol";

contract PeupleTaxesHub is Ownable {

    using SafeERC20 for IERC20;

    address public token = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public walletStaking = 0x9Eb9192ae8C71E7e457257F9efe84ab696379ADB;
    address public walletBank = 0x29935355De0a2Dd402322ea1a1b1524ce22d9c69;

    uint public taxBank = 0;
    uint public taxStaking = 0;

    uint public leftovers = 0;

    constructor() {
    }

    // SETTERS
    
    function setToken(address _token) external onlyOwner {
        token = _token;
    }

    function setWalletBank(address _walletBank) external onlyOwner {
        walletBank = _walletBank;
    }

    function setWalletStaking(address _walletStaking) external onlyOwner {
        walletStaking = _walletStaking;
    }

    function setTaxBank(uint _taxBank) external onlyOwner {
        require(_taxBank <= 100);
        taxBank = _taxBank;
    }

    function setTaxStaking(uint _taxStaking) external onlyOwner {
        require(_taxStaking <= 100);
        taxStaking = _taxStaking;
    }

    // UTILS

    function applyTax(uint value, uint tax) internal pure returns(uint) {
        require(value > 1000, "Peuple Taxes Hub: Too small amount to apply taxes");
        return value * tax / 100;
    }

    // VIEW

    function getTaxesBalance() public view returns(uint balanceBank, uint balanceStaking, uint balanceLeftovers) {
        uint balance = IERC20(token).balanceOf(address(this));

        balanceBank = applyTax(balance, taxBank);
        balanceStaking = applyTax(balance, taxStaking);
        balanceLeftovers = balance - (applyTax(balance, taxBank) + applyTax(balance, taxStaking));

        return (balanceBank, balanceStaking, balanceLeftovers);
    }

    // DISTRIBUTE

    function distribute() external onlyOwner returns (uint left) {
        uint balance = IERC20(token).balanceOf(address(this));

        // Staking
        IERC20(token).approve(walletStaking, applyTax(balance, taxStaking));
        IPeupleStaking(walletStaking).sendCakeRewards(applyTax(balance, taxStaking));
        // Bank
        IERC20(token).safeTransfer(walletBank, applyTax(balance, taxBank));

        // Rounding error
        leftovers = balance - (applyTax(balance, taxBank) + applyTax(balance, taxStaking));
        return leftovers;
    }

    function collectLeftovers() external onlyOwner {
        require(leftovers > 0, "Peuple Taxes Hub: There is 0 leftovers to collect");
        IERC20(token).safeTransfer(msg.sender, leftovers);
        leftovers = 0;
    }
}
