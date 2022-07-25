//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract Marketplace is ReentrancyGuard, IERC721Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private _counter;
    address payable marketOwner;
    uint256 listingPrice = 0.025 ether;
    mapping(uint256 => MarketItem) idToMarketItem;
    uint256[] private _itemIds;
    // Events
    event ItemListed(
        address indexed seller,
        uint256 indexed tokenId,
        address nftAddress
    );
    event ItemSold(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        address nftAddress
    );

    struct MarketItem {
        uint256 itemId;
        uint256 tokenId;
        address nftAddress;
        address payable owner;
        address lastSeller;
        address[] prevOwners;
        uint256 lastPrice;
        uint256 price;
        bool onSale;
    }

    constructor() {
        marketOwner = payable(msg.sender);
    }

    /// Just add to order book without exposing to users (by assigning onSale = false)
    function createMarketItem(uint256 tokenId, address nftContract)
        public
        returns (uint256 itemId)
    {
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Only the owner of this NFT can create a market item"
        );
        itemId = _counter.current();
        _counter.increment();
        address[] memory prevOwners;

        idToMarketItem[itemId] = MarketItem(
            itemId,
            tokenId,
            nftContract,
            payable(msg.sender),
            payable(address(0)),
            prevOwners,
            0,
            0,
            false
        );

        _itemIds.push(itemId);
    }

    /// First make sure: that owner is the one listing the NFT and that the listing fee is correct.
    /// Then Transfer the nft to this contract and the fee to the owner and expose the order to the users.
    function listItemOnSale(uint256 itemId, uint256 price) public payable {
        require(
            idToMarketItem[itemId].owner == msg.sender,
            "Only the owner can list this NFT"
        );
        require(
            listingPrice == msg.value,
            "Listing price should be 0.025 ether"
        );

        address nftContract = idToMarketItem[itemId].nftAddress;
        uint256 tokenId = idToMarketItem[itemId].tokenId;

        IERC721(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        marketOwner.transfer(msg.value);

        idToMarketItem[itemId].price = price;
        idToMarketItem[itemId].lastSeller = msg.sender;
        idToMarketItem[itemId].onSale = true;

        emit ItemListed(msg.sender, tokenId, nftContract);
    }

    ///Owner can't sell their own NFT, msg.value must equal the asking price
    function sellMarketItem(uint256 itemId) public payable nonReentrant {
        uint256 value = msg.value;
        address sender = msg.sender;
        address nftAddress = idToMarketItem[itemId].nftAddress;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        address payable owner = idToMarketItem[itemId].owner;

        uint256 askingPrice = idToMarketItem[itemId].price;

        require(
            askingPrice == value,
            "Buying price must equal the asking price"
        );
        require(owner != sender, "Owner cannot sell their own item");

        IERC721(nftAddress).safeTransferFrom(address(this), sender, tokenId);
        owner.transfer(value);

        idToMarketItem[itemId].owner = payable(sender);
        idToMarketItem[itemId].lastSeller = owner;
        idToMarketItem[itemId].prevOwners.push(owner);
        idToMarketItem[itemId].lastPrice = value;
        idToMarketItem[itemId].price = 0;
        idToMarketItem[itemId].onSale = false;

        emit ItemSold(owner, sender, tokenId, nftAddress);
    }

    ///First understand how many market items we have, then how many of them are on sale and add to list.
    function fetchAllItemsOnSale() external view returns (MarketItem[] memory) {
        uint256 totalMarketItems = _itemIds.length;
        MarketItem[] memory itemsOnSale = new MarketItem[](totalMarketItems);
        uint256 index = 0;

        for (uint256 i = 0; i < totalMarketItems; i++) {
            uint256 itemId = _itemIds[i];
            MarketItem memory item = idToMarketItem[itemId];
            if (item.onSale) {
                itemsOnSale[index] = item;
                index++;
            }
        }

        return itemsOnSale;
    }

    function fetchAllItemsOfOwner()
        external
        view
        returns (MarketItem[] memory)
    {
        uint256 totalMarketItems = _itemIds.length;
        MarketItem[] memory ownerItems = new MarketItem[](totalMarketItems);
        uint256 index = 0;

        for (uint256 i = 0; i < totalMarketItems; i++) {
            uint256 itemId = _itemIds[i];
            MarketItem memory item = idToMarketItem[itemId];
            if (item.owner == msg.sender) {
                ownerItems[index] = item;
                index++;
            }
        }

        return ownerItems;
    }

    function fetchAllItems() external view returns (MarketItem[] memory) {
        uint256 totalMarketItems = _itemIds.length;
        MarketItem[] memory allItems = new MarketItem[](totalMarketItems);
        uint256 index = 0;

        for (uint256 i = 0; i < totalMarketItems; i++) {
            uint256 itemId = _itemIds[i];
            MarketItem storage item = idToMarketItem[itemId];
            allItems[index] = item;
            index++;
        }

        return allItems;
    }

    //     function fetchAllItems() public view returns(MarketItem[] memory){
    //     uint itemsCount = _counter.current();
    //     MarketItem[] memory marketItems = new MarketItem[](itemsCount);

    //     for(uint i = 0; i < itemsCount; i++){
    //         MarketItem storage currentItem = idToMarketItem[i+1];
    //         marketItems[i] = currentItem;
    //     }

    //     return marketItems;
    // }

    ///@dev - Try to extract common functionality from @function fetchAllItemsOnSale(),
    ///fetchItemsForOwner() and fetchAllItems()
    // function _fetchItems() private view returns (MarketItem[] memory){ }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return this.onERC721Received.selector;
    }
}
