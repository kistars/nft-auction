// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./NFTAuction.sol";

contract NFTFactory {
    address[] public auctionAddrs;

    function createAuction() public {
        NFTAuction auction = new NFTAuction();
        auction.initialize(msg.sender);
        auctionAddrs.push(address(auction));
    }

    function getAuctionInstance(uint256 auctionId) public view returns (address) {
        return auctionAddrs[auctionId];
    }
}
