// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Visor Finance (Dec 2021, $8.2M). A registry mapping returned an
/// attacker-controlled implementation address used by delegatecall, letting
/// the attacker arbitrary-write the proxy's storage.
contract VisorLike {
    address public owner;
    mapping(bytes32 => address) public implementations;

    constructor() {
        owner = msg.sender;
    }

    // Bug: missing access control on implementation registration.
    function setImplementation(bytes32 name, address impl) external {
        implementations[name] = impl;
    }

    function execute(bytes32 name, bytes calldata data) external returns (bytes memory) {
        address impl = implementations[name];
        (bool ok, bytes memory ret) = impl.delegatecall(data);
        require(ok, "!delegatecall");
        return ret;
    }
}
