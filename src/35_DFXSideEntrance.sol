// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface DFXFlashBorrower {
    function dfxFlashCallback() external payable;
}

/// @notice DFX Finance (Nov 2022, ~$7.5M). The real curve let a borrower take
/// a flash loan, deposit the borrowed assets during the callback, satisfy the
/// pool-balance repayment check, keep the freshly minted LP claim, then withdraw
/// after the flash loan finished.
contract DFXLikeCurve {
    mapping(address => uint256) public lpBalance;
    uint256 public totalLiquidity;
    bool internal inFlash;

    function seed() external payable {
        totalLiquidity += msg.value;
    }

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");
        lpBalance[msg.sender] += msg.value;
        totalLiquidity += msg.value;
    }

    function withdraw(uint256 lpAmount) external {
        require(lpBalance[msg.sender] >= lpAmount, "lp");
        require(address(this).balance >= lpAmount, "cash");

        lpBalance[msg.sender] -= lpAmount;
        totalLiquidity -= lpAmount;
        (bool ok,) = msg.sender.call{value: lpAmount}("");
        require(ok, "send");
    }

    function flash(uint256 amount, DFXFlashBorrower borrower) external {
        require(!inFlash, "nested flash");
        require(amount > 0 && address(this).balance >= amount, "liquidity");

        uint256 balanceBefore = address(this).balance;
        inFlash = true;
        borrower.dfxFlashCallback{value: amount}();
        inFlash = false;

        // Bug: a raw balance check treats callback deposits as repayment even
        // though those deposits minted LP tokens that can be withdrawn later.
        require(address(this).balance >= balanceBefore, "not repaid");
    }
}
