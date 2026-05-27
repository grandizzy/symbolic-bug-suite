// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Akutar (Apr 2022, $34M locked). The refund loop reverted the
/// entire batch if any single bidder's address rejected the incoming
/// transfer, permanently locking the contract's ETH.
contract AuctionLike {
    address[] public bidders;
    mapping(address => uint256) public refunds;
    bool public refunded;

    function bid(address bidder) external payable {
        bidders.push(bidder);
        refunds[bidder] += msg.value;
    }

    function processRefunds() external {
        require(!refunded, "done");
        for (uint256 i = 0; i < bidders.length; i++) {
            address b = bidders[i];
            uint256 amt = refunds[b];
            refunds[b] = 0;
            (bool ok, ) = b.call{value: amt}("");
            // Bug: one failing recipient blocks every refund forever.
            require(ok, "send failed");
        }
        refunded = true;
    }
}
