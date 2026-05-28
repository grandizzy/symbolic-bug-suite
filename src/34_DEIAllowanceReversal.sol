// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice DEI / Deus DAO (May 2023, ~$6.5M). The deployed token's
/// `burnFrom` allowance bookkeeping used the owner/spender pair in the wrong
/// direction. An attacker could approve a victim, call `burnFrom(victim, 0)`,
/// and accidentally create an allowance from the victim back to the attacker.
contract DEILike {
    string public constant name = "DEI-like stablecoin";
    string public constant symbol = "DEI";
    uint8 public constant decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "allowance");
        require(balanceOf[from] >= amount, "balance");

        allowance[from][msg.sender] = allowed - amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    // Bug: reads allowance[msg.sender][account], but writes the remaining
    // allowance to allowance[account][msg.sender]. With amount == 0 this turns
    // an attacker->victim approval into a victim->attacker approval.
    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = allowance[msg.sender][account];
        require(currentAllowance >= amount, "burn allowance");

        allowance[account][msg.sender] = currentAllowance - amount;
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(balanceOf[account] >= amount, "burn balance");
        balanceOf[account] -= amount;
        totalSupply -= amount;
    }
}
