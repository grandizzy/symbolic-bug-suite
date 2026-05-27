// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {DAOLike} from "../src/30_TheDAOReentrancy.sol";

contract DAOAttacker {
    DAOLike public dao;
    bool entered;

    constructor(DAOLike _d) {
        dao = _d;
    }

    function attack() external payable {
        dao.deposit{value: msg.value}();
        dao.withdraw();
    }

    receive() external payable {
        if (!entered && address(dao).balance > 0) {
            entered = true;
            dao.withdraw();
        }
    }
}

contract TheDAOReentrancyTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function checkWithdrawCannotBeReentered(uint256 attackerDeposit) public payable {
        if (attackerDeposit == 0 || attackerDeposit > 50 ether) return;
        vm.deal(address(this), 1000 ether);

        DAOLike dao = new DAOLike();
        dao.deposit{value: 100 ether}(); // seed liquidity from other LPs

        DAOAttacker atk = new DAOAttacker(dao);
        vm.deal(address(atk), attackerDeposit);
        atk.attack{value: attackerDeposit}();

        assert(address(atk).balance <= attackerDeposit);
    }
}
