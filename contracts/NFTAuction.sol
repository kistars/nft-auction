// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// NFT拍卖
contract NFTAuction is UUPSUpgradeable {
    struct Auction {
        address seller;
        uint256 duration;
        uint256 startPrice;
        uint256 startTimestamp;
        bool ended;
        address highestBidder;
        uint256 highestBid; // 单位统一为出价资产本币
        address nftContract;
        uint256 tokenId;
        address tokenAddress; // 出价使用的资产类型（ETH 或 ERC20）
    }

    mapping(uint256 => Auction) public auctions;
    uint256 public nextAuctionId;
    address public admin;
    mapping(address => AggregatorV3Interface) public priceFeeds;

    // 事件
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, address nftContract, uint256 tokenId);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, address tokenAddress);
    event AuctionEnded(uint256 indexed auctionId, address winner, uint256 amount, address tokenAddress);

    function initialize(address _admin) public initializer {
        admin = _admin;
    }

    function setPriceFeed(address tokenAddress, address _priceFeed) public {
        require(msg.sender == admin, "only admin");
        priceFeeds[tokenAddress] = AggregatorV3Interface(_priceFeed);
    }

    function getChainlinkDataFeedLatestAnswer(address tokenAddress) public view returns (int256) {
        AggregatorV3Interface priceFeed = priceFeeds[tokenAddress];
        require(address(priceFeed) != address(0), "no price feed");
        (, int256 answer,,,) = priceFeed.latestRoundData();
        return answer;
    }

    function getAdjustedPrice(address tokenAddress) internal view returns (uint256) {
        int256 price = getChainlinkDataFeedLatestAnswer(tokenAddress);
        require(price > 0, "invalid price");
        return uint256(price) * 1e10; // 转为18位精度
    }

    function createAuction(uint256 _duration, uint256 _startPrice, address _nftContract, uint256 _tokenId) public {
        require(msg.sender == admin, "Only admin can create");
        require(_duration > 0 && _startPrice > 0, "invalid auction params");

        // 转入NFT
        IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);

        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            duration: _duration,
            startPrice: _startPrice,
            startTimestamp: block.timestamp,
            ended: false,
            highestBid: 0,
            highestBidder: address(0),
            nftContract: _nftContract,
            tokenId: _tokenId,
            tokenAddress: address(0)
        });

        emit AuctionCreated(nextAuctionId, msg.sender, _nftContract, _tokenId);
        nextAuctionId++;
    }

    function placeBid(uint256 _auctionId, uint256 amount, address _tokenAddress) external payable {
        Auction storage auction = auctions[_auctionId];
        require(!auction.ended, "auction ended");
        require(block.timestamp <= auction.startTimestamp + auction.duration, "auction expired");

        uint256 bidValueInUSD;
        if (_tokenAddress == address(0)) {
            require(msg.value == amount, "msg.value mismatch");
            bidValueInUSD = msg.value * getAdjustedPrice(address(0));
        } else {
            require(msg.value == 0, "do not send ETH for ERC20");
            bidValueInUSD = amount * getAdjustedPrice(_tokenAddress);
        }

        uint256 startPriceInUSD = auction.startPrice
            * getAdjustedPrice(auction.tokenAddress == address(0) ? address(0) : auction.tokenAddress);
        uint256 highestBidInUSD = auction.highestBid * getAdjustedPrice(auction.tokenAddress);

        require(bidValueInUSD >= startPriceInUSD && bidValueInUSD > highestBidInUSD, "bid too low");

        // 先收钱
        if (_tokenAddress == address(0)) {
            // ETH 已经通过 msg.value 转入，无需额外处理
        } else {
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount);
        }

        // 退还上一出价者
        if (auction.highestBidder != address(0)) {
            if (auction.tokenAddress == address(0)) {
                payable(auction.highestBidder).transfer(auction.highestBid); // 返还ETH
            } else {
                IERC20(auction.tokenAddress).transfer(auction.highestBidder, auction.highestBid);
            }
        }

        // 更新拍卖状态
        auction.highestBidder = msg.sender;
        auction.highestBid = amount;
        auction.tokenAddress = _tokenAddress;

        emit BidPlaced(_auctionId, msg.sender, amount, _tokenAddress);
    }

    function endAuction(uint256 _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        require(!auction.ended, "already ended");
        require(block.timestamp >= auction.startTimestamp + auction.duration, "auction still active");

        auction.ended = true;

        if (auction.highestBidder == address(0)) {
            // 无人出价，NFT返还给卖家
            IERC721(auction.nftContract).safeTransferFrom(address(this), auction.seller, auction.tokenId);
        } else {
            // 拍卖成功：NFT转移给买家，资金留在合约中，可后续withdraw
            IERC721(auction.nftContract).safeTransferFrom(address(this), auction.highestBidder, auction.tokenId);
        }

        emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBid, auction.tokenAddress);
    }

    // uups，只有管理员才能升级合约
    function _authorizeUpgrade(address) internal view override {
        require(msg.sender == admin, "only admin can upgrade");
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
