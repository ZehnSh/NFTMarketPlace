// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract NFTContract721 is ERC721 {
    constructor() ERC721("MyNFT", "MNFT") {
    }

    function mint(uint256 tokenId) external {
        _mint(msg.sender,tokenId);

    }
}

contract NFTContract1155 is ERC1155, Ownable {
    constructor() ERC1155("") {

    }

     function mint(uint256 id, uint256 amount, bytes memory data)public
    {
        _mint(msg.sender, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
}
contract NFTAuction{

    address payable public seller;
    
    


    uint nftID;
    mapping(uint=>NFTLister) public nftlister;
    struct NFTLister {
        IERC1155 nft1;
        IERC721 nft2;
        uint auctionType;
        uint price;
        address payable sellerAddress;
        uint highestBid;
        address highestBidder;
        mapping(address => uint) bids;
        uint ListerNFT_ID;
        bool started;
        bool ended;
        uint endAt;
    }



    function listNFT_ERC721(address _nft,uint _nftID,uint _startingBid,uint8 AuctionType) external {
        require(AuctionType==1||AuctionType==2,"Please choose correct auction type");
        nftID+=1;
        if(AuctionType==1){
            nftlister[nftID].nft2= IERC721(_nft);
            nftlister[nftID].auctionType=AuctionType;
            nftlister[nftID].ListerNFT_ID = _nftID;
            nftlister[nftID].sellerAddress = payable(msg.sender);
            nftlister[nftID].price = _startingBid;
        }
        else{
        nftlister[nftID].nft2= IERC721(_nft);
        nftlister[nftID].sellerAddress = payable(msg.sender);
        nftlister[nftID].ListerNFT_ID = _nftID;
        nftlister[nftID].highestBid = _startingBid;
        nftlister[nftID].auctionType=AuctionType;
        }
    }

     function listNFT_ERC1155(address _nft,uint _nftID,uint _startingBid,uint8 AuctionType) external {
        require(AuctionType==1||AuctionType==2,"Please choose correct auction type");
        nftID+=1;
        
         if(AuctionType==1){
             nftlister[nftID].nft1= IERC1155(_nft);
            nftlister[nftID].auctionType=AuctionType;
            nftlister[nftID].sellerAddress = payable(msg.sender);
            nftlister[nftID].price = _startingBid;

        }
        else{
        nftlister[nftID].nft1= IERC1155(_nft);
        nftlister[nftID].sellerAddress = payable(msg.sender);
        nftlister[nftID].ListerNFT_ID = _nftID;
        nftlister[nftID].highestBid = _startingBid;
        nftlister[nftID].auctionType=AuctionType;
        }
    }

    function start(uint _nftID) external payable {
        require(nftlister[_nftID].auctionType==2,"This nft is for fixed sale");
        require(nftlister[_nftID].started==false, "started");
        require(nftlister[_nftID].sellerAddress == msg.sender, "not seller");

        if(nftlister[_nftID].nft2==IERC721(0x0000000000000000000000000000000000000000)){
        nftlister[_nftID].nft2.transferFrom(msg.sender, address(this), nftlister[_nftID].ListerNFT_ID);
         } else {
             nftlister[_nftID].nft1.safeTransferFrom(msg.sender, address(this), nftlister[_nftID].ListerNFT_ID,1,"");
         }
        nftlister[_nftID].started = true;
        nftlister[_nftID].endAt = block.timestamp + 2 minutes;

   
    }

    function bid(uint _nftID) external payable {
        require(nftlister[_nftID].auctionType==2,"This nft is for fixed sale");
        require(nftlister[_nftID].started, "not started");
        require(block.timestamp < nftlister[_nftID].endAt, "ended");
        require(msg.value > nftlister[_nftID].highestBid, "value < highest");

        if ( nftlister[_nftID].highestBidder != address(0)) {
            nftlister[_nftID].bids[nftlister[_nftID].highestBidder] +=  nftlister[_nftID].highestBid;
        }

        nftlister[_nftID].highestBidder = msg.sender;
        nftlister[_nftID].highestBid = msg.value;
    }



    function withdraw(uint _nftID) external {
        require(nftlister[_nftID].auctionType==2,"This nft is for fixed sale");
        uint bal =  nftlister[_nftID].bids[msg.sender];
        nftlister[_nftID].bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

    }

    function end(uint _nftID) external {
        require(nftlister[_nftID].auctionType==2,"This nft is for fixed sale");
        require(nftlister[_nftID].started, "not started");
        require(block.timestamp >= nftlister[_nftID].endAt, "not ended");
        require(nftlister[_nftID].ended==false, "ended");

        nftlister[_nftID].ended = true;
        if (nftlister[_nftID].highestBidder != address(0)) {

             if(nftlister[_nftID].nft2==IERC721(0x0000000000000000000000000000000000000000)){
           nftlister[_nftID].nft1.safeTransferFrom(address(this), nftlister[_nftID].highestBidder, nftlister[_nftID].ListerNFT_ID,1,"");
             }else{
           nftlister[_nftID].nft2.safeTransferFrom(address(this), nftlister[_nftID].highestBidder, nftlister[_nftID].ListerNFT_ID);
             }
            nftlister[_nftID].sellerAddress.transfer(nftlister[_nftID].highestBid);
        } else {
            if(nftlister[_nftID].nft2==IERC721(0x0000000000000000000000000000000000000000)){
            nftlister[_nftID].nft1.safeTransferFrom(address(this), nftlister[_nftID].sellerAddress, nftlister[_nftID].ListerNFT_ID,1,"");
            } else {
            nftlister[_nftID].nft2.safeTransferFrom(address(this), nftlister[_nftID].sellerAddress, nftlister[_nftID].ListerNFT_ID);
            }
            nftlister[_nftID].sellerAddress.transfer(nftlister[_nftID].highestBid);
        }
    }

    function buyNFTforFixPrice(uint _nftID) external payable {
       require(nftlister[_nftID].auctionType==1,"This nft is for Auction sale");
       require(msg.value>=nftlister[_nftID].price,"Not enough ether");

       if(nftlister[_nftID].nft2==IERC721(0x0000000000000000000000000000000000000000)){
            nftlister[_nftID].nft1.safeTransferFrom(address(this), nftlister[_nftID].sellerAddress, nftlister[_nftID].ListerNFT_ID,1,"");
            } else {
            nftlister[_nftID].nft2.safeTransferFrom(address(this), nftlister[_nftID].sellerAddress, nftlister[_nftID].ListerNFT_ID);
            }

        nftlister[_nftID].sellerAddress.transfer(calculatePrice(nftlister[_nftID].price));
}

function calculatePrice(uint _amount) internal pure returns(uint) {
  return (_amount -(_amount * 25)/1000);

}

    function balance() external view returns(uint) {
        return address(this).balance;
    }



}
