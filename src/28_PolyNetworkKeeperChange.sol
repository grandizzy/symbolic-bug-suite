// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Poly Network (Aug 2021, $611M). A cross-chain message router
/// dispatched user-provided selectors against trusted state. The attacker
/// crafted a message whose selector matched `putCurEpochConPubKeyBytes`,
/// rotating the trusted keeper to themselves.
contract PolyLike {
    address public keeper;

    constructor(address _keeper) {
        keeper = _keeper;
    }

    function putCurEpochConPubKeyBytes(address newKeeper) external {
        // Real bug: any inbound message could reach this without keeper check.
        keeper = newKeeper;
    }

    // Cross-chain executor that delegates to selectors on this contract.
    function executeCrossChainMessage(bytes calldata data) external {
        (bool ok, ) = address(this).call(data);
        require(ok, "!exec");
    }
}
