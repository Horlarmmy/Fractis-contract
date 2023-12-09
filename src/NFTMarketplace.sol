// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import {IFractionToken} from "./interface/IFractionToken.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarketplace {
    /////////////// STATE VARIABLES ////////////////////
    ListNFT[] public allNFTs;

    ////////////// STRUCTS  ////////////////////

    struct ListNFT {
        uint256 tokenId;
        uint256[] partIds;
        address owner;
    }

    struct Part {
        uint256 id;
        string url;
        uint256 price;
    }
    /////////////// MAPPING ////////////////////
    mapping(uint256 => mapping(uint256 => Part)) public parts;
    mapping(address => mapping(uint256 => ListNFT)) public ownerNFT;
    mapping(uint256 => address) userWinner;

    /////////////// EVENTS ////////////////////
    event NFTCreated(uint256 tokenId, uint256[] partIds, address owner);
    event PartURIUpdated(uint256 tokenId, uint256 partId, string newURI);
    event WinnerRewarded(address winner, uint256 tokenId);

    event BoughtNFT(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 price,
        address indexed buyer,
        uint256 chainid
    );

    constructor() {}

    // @functions
    // Function to create a new NFT with associated partIds and TokenURIs
    function createNFT(
        uint256 tokenId,
        string[] memory tokenURIs,
        uint256[] memory _ids,
        uint256[] memory _prices
    ) public {
        uint256[] memory newPartIds = new uint256[](9);

        // Create parts mapping for each tokenId and partId
        for (uint256 i = 0; i < 9; i++) {
            parts[tokenId][_ids[i]] = Part({id: _ids[i], url: tokenURIs[i], price: _prices[i]});
            newPartIds[i] = _ids[i];
        }

        // Create ListNFT instance and update mappings
        ListNFT memory newListNFT = ListNFT(tokenId, newPartIds, msg.sender);
        ownerNFT[msg.sender][tokenId] = newListNFT;
        allNFTs.push(newListNFT);

        emit NFTCreated(tokenId, newPartIds, msg.sender);
    }

     function buyNFT(
        uint256 _tokenId,
        address _nft
    ) public payable  {
        // Retrieve the NFT listing from the mapping using contract address and token ID
        ListNFT storage listNft = ownerNFT[msg.sender][_tokenId];
        uint256 price = getTotalNFTPrice(_tokenId);

        // Check if the amount sent is sufficient to purchase the NFT
        require(price >= msg.value, "Not sufficient amount sent");    
        (bool success,) = payable(address(this)).call{value: msg.value}("");
        require(success, "Unable to send Ether");

        // Transfer the NFT to the buyer
        IERC721(_nft).safeTransferFrom(
            address(this),
            msg.sender,
            listNft.tokenId
        );

        // Mark the NFT as sold
        listNft.owner = msg.sender;

        // Emit the BoughtNFT event to notify about the successful purchase
        emit BoughtNFT(
            _nft,
            listNft.tokenId,
            msg.value,
            msg.sender,
            block.chainid
        );

        // Delete the NFT listing from the marketplace after the event is emitted
        delete ownerNFT[msg.sender][_tokenId];
    }

    // function cancelListing(uint256 _tokenId, address _nft) public {
    //     ListNFT memory listedNft = _listNfts[msg.sender][_tokenId];
    //     if (listedNft.sold == true) {
    //         revert SomidaxMarketPlace__NFTAlreadySold();
    //     }
    //     IERC721 nft = IERC721(_nft);
    //     require(
    //         nft.ownerOf(_tokenId) == msg.sender,
    //         "Only Owners can cancel NFT"
    //     );

    //     delete _listNfts[msg.sender][_tokenId];
    // }

    /////////// @notice This would check if the part is correct
    /////////// @dev The function arePartsCorrect() returns true or false
    ///////////      if true, it means the user sent [1,2,3,4,5,6,7,8,9] and we reward the user
    /////////// @param Array of Numbers
    function checkParts(
        uint256[9] memory _numbers,
        uint256 _tokenId,
        address owner
    ) external {
        bool didUserWin = arePartsCorrect(_numbers, owner, _tokenId);

        require(didUserWin, "Unable to match paths, Please try again");
        rewardWinner(_tokenId);
    }

    function rewardWinner(uint256 _tokenId) private {
        userWinner[_tokenId] = msg.sender;
        emit WinnerRewarded(msg.sender, _tokenId);
    }

    //////////////// GETTERS (PURE AND VIEW)/////////////////////////

    function extractValues(
        uint256 bigNumber
    ) public pure returns (uint256[18] memory) {
        uint256[18] memory values;
        bool inArray;

        for (uint i = 0; i < 18; i++) {
            inArray = false;
            // We use modulo operation to get the remainder of the bigNumber divided by 10
            uint256 digit = bigNumber % 10;

            // Check if the digit already exists in the values array
            for (uint256 i2 = 0; i2 < values.length; i2++) {
                if (digit == values[i2]) {
                    inArray = true;
                    break;
                }
            }

            // If the digit is not in the array, add it
            if (!inArray) {
                values[i] = digit;
            }

            // We then divide the bigNumber by 10 to effectively remove the last digit
            bigNumber = bigNumber / 10;
        }

        return values;
    }

    function arePartsCorrect(
        uint256[9] memory _numbers,
        address owner,
        uint256 tokenId
    ) internal view returns (bool _ifWon) {
        uint256[] memory ids = ownerNFT[owner][tokenId].partIds;

        for (uint256 i = 0; i < 9; i++) {
            // Check if the number matches the index (1 to 9)
            if (_numbers[i] != ids[i]) {
                // If there's a match, call the callback function
                return false;
            }
        }
        return true;
    }

    function checkWinner(
        uint256 _tokenId
    ) external view returns (address _winnerAddr) {
        return userWinner[_tokenId];
    }

    // Function to get the ListNFT associated with the calling address
    function getListNFT(uint256 tokenId)
        public
        view
        returns (uint256, uint256[] memory, address)
    {
        ListNFT memory userNFT = ownerNFT[msg.sender][tokenId];
        return (userNFT.tokenId, userNFT.partIds, userNFT.owner);
    }

    // Function to get all NFTs created, useful for listing all NFTs
    function getAllNFTs() public view returns (ListNFT[] memory) {
        return allNFTs;
    }

    // Additional getter to retrieve the URI associated with a specific partId and tokenId
    function getPartURI(
        uint256 tokenId,
        uint256 partId
    ) public view returns (Part memory) {
        return parts[tokenId][partId];
    }

      function getTotalNFTPrice(
        uint256 tokenId
    ) public view returns (uint256) {
        uint256 totalAmount;
        ListNFT memory userNFT = ownerNFT[msg.sender][tokenId];
        for (uint256 i; i < userNFT.partIds.length; i++)
        {
         Part memory part =  parts[tokenId][userNFT.partIds[i]];
         totalAmount += part.price;
        }
        return totalAmount;
    }
}
