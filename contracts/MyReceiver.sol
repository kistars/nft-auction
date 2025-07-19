// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

interface INFTAuction {
    function placeBid(uint256 _auctionId, uint256 _amount, address _tokenAddress) external payable;
}

contract MyReceiver is CCIPReceiver {
    address public auctionContrat;

    constructor(address _router, address _auctionContract) CCIPReceiver(_router) {
        auctionContrat = _auctionContract;
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        (uint256 auctionId, uint256 amount, address tokenAddress) =
            abi.decode(message.data, (uint256, uint256, address));

        INFTAuction(auctionContrat).placeBid(auctionId, amount, tokenAddress); // 出价
    }
}
