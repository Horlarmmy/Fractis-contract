// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTStakingContract is Ownable {
    IERC721 public nft;
    IERC20 public rewardToken;

    struct Stake {
        address owner;
        uint256 stakedTime;
        uint256 tokenId;
    }

    mapping(uint256 => Stake) public stakes;
    mapping(address => uint256) public rewards;

    uint256 public constant APY = 5; // 5% annual yield

    constructor(address _nftAddress, address _rewardTokenAddress) Ownable(msg.sender) {
        nft = IERC721(_nftAddress);
        rewardToken = IERC20(_rewardTokenAddress);
    }

    function stakeNFT(uint256 _tokenId) public {
        require(nft.ownerOf(_tokenId) == msg.sender, "You must own the NFT");
        nft.transferFrom(msg.sender, address(this), _tokenId);

        stakes[_tokenId] = Stake({
            owner: msg.sender,
            stakedTime: block.timestamp,
            tokenId: _tokenId
        });
    }

    function calculateYield(uint256 _tokenId) public view returns (uint256) {
        Stake memory stake = stakes[_tokenId];
        uint256 stakedDuration = block.timestamp - stake.stakedTime;
        uint256 yearlyYield = nftValue(_tokenId) * APY / 100;
        return yearlyYield * stakedDuration / 365 days;
    }

    function unstakeNFT(uint256 _tokenId) public {
        require(stakes[_tokenId].owner == msg.sender, "You must be the owner");

        uint256 yield = calculateYield(_tokenId);
        rewardToken.transfer(msg.sender, yield);
        nft.transferFrom(address(this), msg.sender, _tokenId);

        delete stakes[_tokenId];
    }

    // Additional functions would be required for NFT valuation
    function nftValue(uint256 _tokenId) public view returns (uint256) {
        // Implement NFT valuation logic or oracle integration
    }

    function isOwnerOfStake(uint256 _tokenId) public view returns (bool) {
    return stakes[_tokenId].owner == msg.sender;
    }

    function getStakeInfo(uint256 _tokenId) public view returns (address owner, uint256 stakedTime, uint256 tokenId) {
    Stake memory stake = stakes[_tokenId];
    return (stake.owner, stake.stakedTime, stake.tokenId);
}
    function transferStake(uint256 _tokenId, address newOwner) public onlyOwner {
    stakes[_tokenId].owner = newOwner;
}
}


pragma solidity ^0.8.0;

// import "./NFTStakingContract.sol";

contract BorrowingAndLendingContract is Ownable {
    NFTStakingContract public stakingContract;
    IERC20 public lendingToken;

    uint256 public constant LTV_RATIO = 50; // Loan to Value ratio of 50%
    uint256 public constant INTEREST_RATE = 10; // Annual interest rate of 10%

    struct Loan {
        uint256 amount;
        uint256 dueDate;
        bool isRepaid;
        address borrower;
    }

    mapping(uint256 => Loan) public loans;

    event loanLiquidated( 
        uint256 tokenId,
        address debtor,
        uint256 outstandingAmount,
        Loan loanInfo
    );

    constructor(address _stakingContractAddress, address _lendingTokenAddress) Ownable(msg.sender) {
        stakingContract = NFTStakingContract(_stakingContractAddress);
        lendingToken = IERC20(_lendingTokenAddress);
    }

    function borrow(uint256 _tokenId, uint256 _amount) public {
        require(stakingContract.isOwnerOfStake(_tokenId), "Not NFT owner");
        uint256 maxLoan = stakingContract.nftValue(_tokenId) * LTV_RATIO / 100;
        require(_amount <= maxLoan, "Amount exceeds LTV ratio");

        lendingToken.transfer(msg.sender, _amount);
        loans[_tokenId] = Loan({
            amount: _amount,
            dueDate: block.timestamp + 365 days,
            isRepaid: false,
            borrower: msg.sender
        });
    }

    function repayLoan(uint256 _tokenId) public {
        Loan storage loan = loans[_tokenId];
        require(!loan.isRepaid, "Loan already repaid");
        require(block.timestamp <= loan.dueDate, "Loan due date passed");
        require(loans[_tokenId].borrower == msg.sender, "caller is not debtor");

        uint256 repaymentAmount = loan.amount + calculateInterest(loan.amount);
        lendingToken.transferFrom(msg.sender, address(this), repaymentAmount);
        loan.isRepaid = true;
    }

    function calculateInterest(uint256 _amount) internal pure returns (uint256) {
        return _amount * INTEREST_RATE / 100;
    }

     // Additional function for loan liquidation
    function liquidateLoan(uint256 _tokenId) public onlyOwner {
        Loan storage loan = loans[_tokenId];
        require(!loan.isRepaid, "Loan already repaid");
        require(block.timestamp > loan.dueDate, "Loan not yet due");
        address debtor = loan.borrower;

        // reclaim staked nft of debtor by transferring owner of nft to contract
        stakingContract.transferStake(_tokenId, address(this));

        uint256 outstandingAmount = loan.amount + calculateInterest(loan.amount);

        loan.isRepaid = false;
        emit loanLiquidated( _tokenId, debtor ,outstandingAmount, loan);
    }
}

contract LiquidityProvidingContract is Ownable {
    IERC20 public liquidityToken;

    struct Deposit {
        uint256 amount;
        uint256 depositTime;
    }

    mapping(address => Deposit) public deposits;

    event DepositMade(address indexed account, uint256 amount);
    event WithdrawalMade(address indexed account, uint256 amount);


    constructor(address _liquidityTokenAddress) Ownable(msg.sender) {
        liquidityToken = IERC20(_liquidityTokenAddress);
    }

    function depositToken(uint256 _amount) public {
        liquidityToken.transferFrom(msg.sender, address(this), _amount);
        deposits[msg.sender] = Deposit({
            amount: _amount,
            depositTime: block.timestamp
        });

        emit DepositMade(msg.sender, _amount);
    }

    function withdraw() public {
        Deposit storage deposit = deposits[msg.sender];
        uint256 interest = calculateInterest(deposit.amount, deposit.depositTime);

        liquidityToken.transfer(msg.sender, deposit.amount + interest);
        delete deposits[msg.sender];

        emit WithdrawalMade(msg.sender, deposit.amount + interest);
    }

    function calculateInterest(uint256 _amount, uint256 _depositTime) internal view returns (uint256) {
        uint256 duration = block.timestamp - _depositTime;
        uint256 annualInterestRate = getDynamicInterestRate(); // Implement dynamic interest rate based on pool utilization
        return _amount * annualInterestRate / 100 * duration / 365 days;
    }

    function getDynamicInterestRate() internal view returns (uint256) {
        // Implement logic to determine interest rate based on pool utilization
        uint256 targetPoolSize = 1000000; // placeholder value 
        uint256 currentPoolSize = liquidityToken.balanceOf(address(this));
        uint256 utilizationRatio = (currentPoolSize * 100) / targetPoolSize;

        if (utilizationRatio >= 90) {
            return 10; // 10% annual interest if the pool is 90% or more utilized
        } else if (utilizationRatio >= 70) {
            return 5; // 5% annual interest if the pool is 70-89% utilized
        } else {
            return 2; // 2% annual interest if the pool is less than 70% utilized
        }
    }

     // Distribute yield to NFT stakers
    // function distributeYield(address _nftStaker, uint256 _yield) external onlyOwner {
    //     require(_nftStaker != address(0), "Invalid address");
    //     require(_yield > 0, "Yield must be greater than 0");

    //     liquidityToken.transfer(_nftStaker, _yield);
    // }

    // // Distribute a portion of the interest paid by borrowers to liquidity providers as a reward
    // function distributeInterestReward(address _liquidityProvider, uint256 _reward) external onlyOwner {
    //     require(_liquidityProvider != address(0), "Invalid address");
    //     require(_reward > 0, "Reward must be greater than 0");

    //     liquidityToken.transfer(_liquidityProvider, _reward);
    // }
}
