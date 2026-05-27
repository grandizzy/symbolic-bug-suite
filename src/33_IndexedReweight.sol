// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Indexed Finance (Oct 2021, $16M). The reweighting math allowed a
/// state where one token's weight could be zeroed via attacker-controlled
/// minting; subsequent swaps treated the zero-weight token as effectively
/// free.
contract IndexedLike {
    mapping(address => uint256) public weight;
    mapping(address => uint256) public reserve;

    function init(address t, uint256 w, uint256 r) external {
        weight[t] = w;
        reserve[t] = r;
    }

    // Bug: subtracts attacker-controlled `delta` from weight without lower bound.
    function reweight(address t, uint256 delta) external {
        weight[t] -= delta;
    }

    function priceFor(address t) external view returns (uint256) {
        return weight[t] == 0 ? 0 : reserve[t] / weight[t];
    }
}
