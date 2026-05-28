// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Fei/Rari Fuse (Apr 2022, ~$80M). The vulnerable Compound fork sent
/// ETH to the borrower before recording the new borrow. During that callback an
/// attacker could leave the market while the debt still appeared to be zero,
/// then reclaim collateral before the borrow accounting caught up.
contract RariFuseLikeMarket {
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public accountBorrows;
    mapping(address => bool) public enteredMarket;

    function seedLiquidity() external payable {}

    function enterAndSupply() external payable {
        require(msg.value > 0, "zero collateral");
        enteredMarket[msg.sender] = true;
        collateral[msg.sender] += msg.value;
    }

    function borrow(uint256 amount) external {
        require(amount > 0, "zero borrow");
        require(_liquidityAfterBorrow(msg.sender, amount), "insolvent");
        require(address(this).balance >= amount, "cash");

        // Bug: interaction before accountBorrows is updated.
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "send");

        accountBorrows[msg.sender] += amount;
    }

    function exitMarket() external {
        require(accountBorrows[msg.sender] == 0, "borrowed");
        enteredMarket[msg.sender] = false;
    }

    function redeemCollateral(uint256 amount) external {
        require(collateral[msg.sender] >= amount, "collateral");
        uint256 remaining = collateral[msg.sender] - amount;
        require(!enteredMarket[msg.sender] || remaining / 2 >= accountBorrows[msg.sender], "shortfall");

        collateral[msg.sender] = remaining;
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "redeem send");
    }

    function _liquidityAfterBorrow(address account, uint256 newBorrow) internal view returns (bool) {
        return enteredMarket[account] && collateral[account] / 2 >= accountBorrows[account] + newBorrow;
    }
}
