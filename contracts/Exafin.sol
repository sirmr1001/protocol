// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IExafin.sol";
import "./utils/TSUtils.sol";
import "hardhat/console.sol";

contract Exafin is Ownable, IExafin {

    using SafeCast for uint256;
    using TSUtils for uint256;
    using SafeERC20 for IERC20;

    event Borrowed(address indexed to, uint amount, uint maturityDate);
    event Lent(address indexed from, uint amount, uint maturityDate);
    
    struct Pool {
        uint256 borrowed;
        uint256 lent;
    }

    mapping(uint256 => mapping(address => uint256)) borrowedAmounts;
    mapping(uint256 => mapping(address => uint256)) lentAmounts; 
    mapping(uint256 => Pool) public pools;
    mapping(address => uint256[]) public addressPools;

    IERC20 private underlying;

    constructor (address stableAddress) onlyOwner {
        underlying = IERC20(stableAddress);
        underlying.safeApprove(address(this), type(uint256).max);
    }

    /**
        @dev Rate that the protocol will pay when borrowing from an address a certain amount
             at the end of the maturity date
        @param amount amount to calculate how it would affect the pool 
        @param maturityDate maturity date to calculate the pool
     */
    function rateBorrow(uint256 amount, uint256 maturityDate) public view returns (uint256, Pool memory) {
        uint dateId = nextPoolIndex(maturityDate);
        require(block.timestamp < dateId, "Exafin: Pool for that date has reached maturity");

        Pool memory pool = pools[dateId];
        pool.lent += amount;

        uint256 daysDifference = (dateId - block.timestamp).trimmedDay() / 1 days;
        uint256 utilizationRatio = pool.borrowed / pool.lent;

        return (utilizationRatio * 15/10 + daysDifference * 5/100, pool);
    }

    /**
        @dev Rate that the protocol will collect when lending to an address a certain amount
             at the end of the maturity date
        @param amount amount to calculate how it would affect the pool 
        @param maturityDate maturity date to calculate the pool
     */
    function rateLend(uint256 amount, uint256 maturityDate) public view returns (uint256, Pool memory) {
        uint dateId = nextPoolIndex(maturityDate);
        require(block.timestamp < dateId, "Exafin: Pool for that date has reached maturity");

        Pool memory pool = pools[dateId];
        pool.borrowed += amount;

        uint256 daysDifference = (dateId - block.timestamp).trimmedDay() / 1 days;
        uint256 utilizationRatio = pool.borrowed / pool.lent;

        return (utilizationRatio * 15/10 + daysDifference * 5/100, pool);
    }

    /**
        @dev Lends to a wallet for a certain maturity date/pool
        @param to wallet to send the amount
        @param amount amount to send to the specified wallet
        @param maturityDate maturity date for repayment
     */
    function lend(address to, uint256 amount, uint256 maturityDate) public {
       
        uint dateId = nextPoolIndex(maturityDate);
        require(block.timestamp < dateId, "Exafin: Pool for that date has reached maturity");

        uint256 lentForDate = lentAmounts[dateId][to];
        require(lentForDate == 0, "Exafin: Wallet already has a loan for this maturity");

        underlying.safeTransferFrom(address(this), to, amount);

        (uint256 commission, Pool memory newPoolState) = rateLend(amount, maturityDate);

        lentAmounts[dateId][to] = amount + commission;
        pools[dateId] = newPoolState;

        emit Lent(to, amount, dateId);
    }

    /**
        @dev Borrows from a wallet for a certain maturity date/pool
        @param from wallet to receive amount from
        @param amount amount to receive from the specified wallet
        @param maturityDate maturity date 
     */
    function borrow(address from, uint256 amount, uint256 maturityDate) public {
        
        uint dateId = nextPoolIndex(maturityDate);
        require(block.timestamp < dateId, "Exafin: Pool for that date has reached maturity");

        uint256 borrowedForDate = borrowedAmounts[dateId][from];
        require(borrowedForDate == 0, "Exafin: Wallet already has a supply for this maturity");

        underlying.safeTransferFrom(from, address(this), amount);

        (uint256 commission, Pool memory newPoolState) = rateBorrow(amount, maturityDate);

        lentAmounts[dateId][from] = amount + commission;
        pools[dateId] = newPoolState;

        emit Borrowed(from, amount, dateId);
    }

    /**
        @dev Converts any timestamp to one of the pool's indexes
        @param timestamp uint
        @return uint256 is the timestamp cropped to match a pool id
     */
    function nextPoolIndex(uint timestamp) private pure returns (uint256) {
        uint poolindex = timestamp.trimmedMonth().nextMonth();
        return poolindex;
    }

}
