// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Audius (Jul 2022, $6M). A storage slot collision between the proxy
/// admin layout and the implementation's governance state let any caller
/// overwrite admin-controlled state by writing to what looked like an
/// innocuous storage variable.
contract AudiusLike {
    address public admin; // slot 0

    constructor(address _admin) {
        admin = _admin;
    }

    // Bug: this "setter" writes to slot 0 — the admin slot.
    function setVotingPeriod(uint256 newPeriod) external {
        assembly {
            sstore(0, newPeriod)
        }
    }
}
