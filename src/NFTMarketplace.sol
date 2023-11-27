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

contract NFTMarketplace {
    /////////////// STATE VARIABLES ////////////////////
    ListNFT[] public allNFTs;

    ////////////// STRUCTS  ////////////////////

    struct ListNFT {
        uint256 tokenId;
        uint256[] partIds;
        address owner;
    }

    /////////////// MAPPING ////////////////////
    mapping(uint256 => mapping(uint256 => string)) public parts;
    mapping(address => ListNFT) public ownerNFT;

    /////////////// EVENTS ////////////////////
    event NFTCreated(uint256 tokenId, uint256[] partIds, address owner);
    event PartURIUpdated(uint256 tokenId, uint256 partId, string newURI);
    event RewardWinner(address winner, uint256 _tokenId);

    constructor() {}

    // @functions
    // Function to create a new NFT with associated partIds and TokenURIs
    function createNFT(uint256 tokenId, string[] memory tokenURIs) public {
        uint256[] memory newPartIds = new uint256[](9);

        // Create parts mapping for each tokenId and partId
        for (uint256 i = 0; i < 9; i++) {
            uint256 partId = i + 1;
            parts[tokenId][partId] = tokenURIs[i];
            newPartIds[i] = partId;
        }

        // Create ListNFT instance and update mappings
        ListNFT memory newListNFT = ListNFT(tokenId, newPartIds, msg.sender);
        ownerNFT[msg.sender] = newListNFT;
        allNFTs.push(newListNFT);

        emit NFTCreated(tokenId, newPartIds, msg.sender);
    }

    /////////// @notice This would check if the part is correct
    /////////// @dev The function matchPaths() returns true or false
    ///////////      if true, it means the user sent [1,2,3,4,5,6,7,8,9] and we reward the user
    /////////// @param Array of Numbers
    function checkParts(uint256[9] memory _numbers, uint256 _tokenId) external {
        bool didUserWin = matchPaths(_numbers);

        require(didUserWin, "Unable to match paths, Please try again");
        rewardWinner(_tokenId);
    }

    function rewardWinner(uint256 _tokenId) internal {
        emit RewardWinner(msg.sender, _tokenId);
    }

    //////////////// GETTERS (PURE AND VIEW)/////////////////////////
    function matchPaths(
        uint256[9] memory _numbers
    ) internal pure returns (bool _ifWon) {
        for (uint256 i = 0; i < 9; i++) {
            // Check if the number matches the index (1 to 9)
            if (_numbers[i] != i + 1) {
                // If there's a match, call the callback function
                return false;
            }
        }
        return true;
    }

    // Function to get the ListNFT associated with the calling address
    function getListNFT()
        public
        view
        returns (uint256, uint256[] memory, address)
    {
        ListNFT memory currentNFT = ownerNFT[msg.sender];
        return (currentNFT.tokenId, currentNFT.partIds, currentNFT.owner);
    }

    // Function to get all NFTs created, useful for listing all NFTs
    function getAllNFTs() public view returns (ListNFT[] memory) {
        return allNFTs;
    }

    // Additional getter to retrieve the URI associated with a specific partId and tokenId
    function getPartURI(
        uint256 tokenId,
        uint256 partId
    ) public view returns (string memory) {
        return parts[tokenId][partId];
    }
}
