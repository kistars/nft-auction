// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./NFTAuction.sol";

contract NFTFactory {
    NFTAuction[] auctionInstance;

    function createAuction(address ccipRouter) public {
        NFTAuction auction = new NFTAuction();
        auction.initialize(msg.sender);
        auctionInstance.push(auction);
    }

    function getAuctionInstance(uint256 auctionId) public view returns (NFTAuction) {
        return auctionInstance[auctionId];
    }
}
