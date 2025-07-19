// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

// ccip消息发送端
contract MySender {
    IRouterClient public router; // 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59, sepolia router地址
    address public receiver; // 接受合约的地址
    address public linkToken;

    constructor(address _router, address _linkToken, address _receiver) {
        router = IRouterClient(_router);
        receiver = _receiver;
        linkToken = _linkToken;
    }

    // 发送拍卖消息
    // @param _tokenAddress: 是否使用ERC20代币出价
    function sendBidMessage(uint64 destinationChainSelector, uint256 _auctionId, uint256 _amount, address _tokenAddress)
        public
        payable
    {
        bytes memory encodedMsg = abi.encode(_auctionId, _amount, _tokenAddress);

        Client.EVM2AnyMessage memory messageParams = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: encodedMsg,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000})),
            feeToken: address(0) // use native gas
        });

        uint256 fee = router.getFee(destinationChainSelector, messageParams);
        require(msg.value >= fee, "Not enough native token to pay fee");

        router.ccipSend{value: msg.value}(destinationChainSelector, messageParams);
    }
}
