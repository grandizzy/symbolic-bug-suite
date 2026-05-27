// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Nexera (Aug 2024, $1.5M). The upgrade entrypoint accepted an
/// arbitrary implementation address and delegatecall'd into it without
/// verifying the caller was the trusted admin, letting an attacker take
/// over the proxy's storage.
contract NexeraLike {
    address public admin;

    constructor(address _admin) {
        admin = _admin;
    }

    // Bug: missing `require(msg.sender == admin)`.
    function upgradeAndCall(address impl, bytes calldata data) external {
        (bool ok, ) = impl.delegatecall(data);
        require(ok, "!delegatecall");
    }
}
