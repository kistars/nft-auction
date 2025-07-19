// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./NFTAuction.sol";

// NFT拍卖
contract NFTAuctionV2 is NFTAuction {
    function upgradeFunction() public pure returns (string memory) {
        return "this is upgraded contract.";
    }
}
