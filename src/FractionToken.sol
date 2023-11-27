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

// @IMPORTANT NOTICE
// @Not sure wie will be needing this contract

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// contract FractionToken is ERC20, ERC20Burnable {
//     address public NFTAddress;
//     uint256 public NFTId;
//     address public NFTOwner;

//     address public ContractDeployer;
//     uint256 public RoyaltyPercentage;

//     address[] tokenOwners;
//     mapping(address => bool) isHolding;

//     constructor(address _NFTAddress, uint256  _NFTId, address _NFTOwner, uint256  _royaltyPercentage, uint256  _supply, string memory _tokenName, string memory _tokenTicker) ERC20(_tokenName, _tokenTicker) {
//         NFTAddress = _NFTAddress;
//         NFTId = _NFTId;
//         NFTOwner = _NFTOwner;
//         RoyaltyPercentage = _royaltyPercentage;

//         ContractDeployer = msg.sender;

//         _mint(_NFTOwner, _supply);
//     }

//     function transfer(address to, uint256 amount) override public returns (bool) {
//         //calculate royalty fee
//         uint royaltyFee = amount * RoyaltyPercentage / 100;
//         uint afterRoyaltyFee = amount - royaltyFee;
//         address owner = _msgSender();

//         //send royalty fee to owner
//         _transfer(owner, NFTOwner, royaltyFee);
//         //send rest to receiver
//         _transfer(owner, to, afterRoyaltyFee);

//        // addNewUserRemoveOld(to, owner);

//         return true;
//     }

//     function transferFrom(
//         address from,
//         address to,
//         uint256 amount
//     ) public virtual override returns (bool) {
//         address spender = _msgSender();
//         _spendAllowance(from, spender, amount);

//         //calculate royalty fee
//         uint royaltyFee = amount * RoyaltyPercentage / 100;
//         uint afterRoyaltyFee = amount - royaltyFee;

//         //send royalty fee to owner
//         _transfer(from, NFTOwner, royaltyFee);
//         //send rest to receiver
//         _transfer(from, to, afterRoyaltyFee);

//         return true;
//     }

//     function burn(uint256 amount) public virtual override {
//         _burn(_msgSender(), amount);
//     }

//     function updateNFTOwner(address _newOwner) public {
//         require(msg.sender == ContractDeployer, "Only contract deployer can call this function");

//         NFTOwner = _newOwner;
//     }

//     function returnTokenOwners() public view returns(address[] memory) {
//         return tokenOwners;
//     }
// }
