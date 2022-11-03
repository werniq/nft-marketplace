// SPDX-License-Identifier: MIT


pragma solidity >= 0.6.0 < 0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftMarket is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _listedItems;
    Counters.Counter private _tokenIds;

    uint256[] private _allNfts;

    
    uint public listingPrice = 0.025 ether;

    mapping(address => mapping(uint => uint)) private _ownerTokens;
    mapping(uint => uint) private _idToOwnedIndex;
    mapping(string => bool) private _usedTokenURIs;
    mapping(uint => NftItem) private _idToNft;
    mapping(uint => uint) private _idToNftIndex;

    struct NftItem {
        uint tokenId;
        uint price;
        address creator;
        bool isListed;
    }

    event NftItemCreated(
        uint tokenId,
        uint price,
        address creator,
        bool isListed
    );

    constructor() ERC721("CreaturesNFT", "CNFT") {}


    function setListingPrice(uint newPrice) external onlyOwner {
        require(newPrice > 0, "Price should be greater then 0");
        listingPrice = newPrice;
    }


    function mintToken(string memory tokenURI, uint price) public payable returns(uint) {
        require(!tokenURIExists(tokenURI), "Token URI already exists");
        require(msg.value >= listingPrice, "Paid not enough");

        _tokenIds.increment();
        _listedItems.increment();

        uint newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        _usedTokenURIs[tokenURI]  = true;
        createNftItem(newTokenId, price);
    
        return newTokenId;
    }


    function getOwnerNfts() public view returns(NftItem[] memory) {
        uint ownedItemsCount = ERC721.balanceOf(msg.sender);
        NftItem[] memory items = new NftItem[](ownedItemsCount);

        for (uint i = 0; i < ownedItemsCount; ++i) {
            uint tokenId = tokenOfOwnerByIndex(i, msg.sender);
            NftItem storage item = _idToNft[tokenId];
            items[i] = item; 
        }

        return items;
    }


    function buyNft(uint tokenId) public payable {
        uint price = _idToNft[tokenId].price;
        address owner = ERC721.ownerOf(tokenId);


        require(msg.value == price, "Please submit the asking price");
        require(msg.sender != owner, "You can not buy your own nft");

        _idToNft[tokenId].isListed = false;
        _listedItems.decrement();

        _transfer(owner, msg.sender, tokenId);
        payable(owner).transfer(msg.value);
    }


    function tokenOfOwnerByIndex(uint index, address owner) public view returns (uint) {
        require(index < ERC721.balanceOf(owner), "Out of bounds");
        return _ownerTokens[owner][index];
    }


    function createNftItem(uint tokenId, uint price) private {
        require(price > 0, "Price must be greater then 0");
        
        _idToNft[tokenId] = NftItem({
            tokenId: tokenId,
            price: price,
            creator: msg.sender,
            isListed: true
        });

        emit NftItemCreated(tokenId, price, msg.sender, true);
    }


    function getNftItem(uint tokenId) public view returns(NftItem memory) {
        return _idToNft[tokenId];
    }


    function getAllNftOnSale() public view returns(NftItem[] memory) {
        uint total = totalSupply();
        uint currentIndex = 0;
        NftItem[] memory items = new NftItem[](_listedItems.current());
    
        for (uint i = 0; i < total; i++) {
            uint tokenId = tokenByIndex(i);
            NftItem storage item = _idToNft[tokenId];

            if (item.isListed == true) {
                items[currentIndex] = item;
                currentIndex++;
            }
        
        }
    
    }


    function listedItemsCount() public view returns(uint) {
        return _listedItems.current();
    }


    function tokenURIExists(string memory tokenURI) public view returns(bool) {
        return _usedTokenURIs[tokenURI] == true;
    }    


    function _removeTokenFromOwnerEnumeration(address from, uint tokenId) private {
        uint lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint tokenIndex = _idToOwnedIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint lastTokenId = _ownerTokens[from][lastTokenIndex];

            _ownerTokens[from][tokenIndex] = lastTokenId;
            _idToOwnedIndex[lastTokenId] = tokenIndex;
        }

        delete _idToOwnedIndex[tokenId];
        delete _ownerTokens[from][lastTokenIndex];
    }


    function _removeTokenFromAllTokensEnumeration(uint tokenId) private {
            uint lastTokenIndex = _allNfts.length - 1;
            uint tokenIndex = _idToNftIndex[tokenId];
            uint lastTokenId = _allNfts[lastTokenIndex];


            _allNfts[tokenIndex] = lastTokenId;
            _idToNftIndex[lastTokenId] = tokenIndex;

            delete _idToNftIndex[tokenId];
            _allNfts.pop();
    }


    function _beforeTokenTransfer(address from, address to, uint tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);


        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        } 

        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(tokenId, to);
        }

        if (to != from) {
            _addTokenToOwnerEnumeration(tokenId, to);
        }
    }


    function placeNftOnSale(uint tokenId, uint newPrice) public payable {
        NftItem memory item = _idToNft[tokenId];
        require(msg.sender == item.creator, "You are not owner of this NFT");
        require(!item.isListed, "Item is already listed");
        require(msg.value == listingPrice, "You should pay 0.025 ether to list item");

        item.isListed = true;
        item.price = newPrice;
        _listedItems.increment();        
    }


    function _addTokenToAllTokensEnumeration(uint tokenId) private {
        _idToNftIndex[tokenId] = _allNfts.length;
        _allNfts.push(tokenId);
    }


    function totalSupply() public view returns(uint) {
        return _allNfts.length;
    }


    function tokenByIndex(uint index) public view returns(uint) {
        require(index < totalSupply(), "Index out of the bounds");
        return _allNfts[index];
    }


    function _addTokenToOwnerEnumeration(uint tokenId, address to) private {
        uint length = ERC721.balanceOf(to);

        _ownerTokens[to][length] = tokenId;
        _idToOwnedIndex[tokenId] = length;
    }
}