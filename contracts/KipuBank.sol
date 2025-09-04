// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract KipuBank is Ownable, ReentrancyGuard {
    IERC20 public token;

    struct Account {
        uint256 balance;
        uint256 lastDepositTimestamp;
        bool exists;
    }

    mapping(address => Account) public accounts;
    uint256 public minimumDeposit = 100 * 10**18; // 100 tokens
    uint256 public withdrawalFee = 5; // 5% fee
    uint256 public lockPeriod = 1 days;

    event AccountCreated(address indexed owner);
    event Deposited(address indexed owner, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount, uint256 fee);
    event MinimumDepositUpdated(uint256 newMinimumDeposit);
    event WithdrawalFeeUpdated(uint256 newWithdrawalFee);
    event LockPeriodUpdated(uint256 newLockPeriod);
    event TokenAddressUpdated(address newTokenAddress);

    constructor(address _tokenAddress) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        token = IERC20(_tokenAddress);
    }

    function createAccount() external {
        require(!accounts[msg.sender].exists, "Account already exists");

        accounts[msg.sender] = Account({
            balance: 0,
            lastDepositTimestamp: 0,
            exists: true
        });

        emit AccountCreated(msg.sender);
    }

    function deposit(uint256 amount) external nonReentrant {
        require(accounts[msg.sender].exists, "Account does not exist");
        require(amount >= minimumDeposit, "Amount below minimum deposit");

        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        accounts[msg.sender].balance += amount;
        accounts[msg.sender].lastDepositTimestamp = block.timestamp;

        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        Account storage account = accounts[msg.sender];
        require(account.exists, "Account does not exist");
        require(account.balance >= amount, "Insufficient balance");
        require(
            block.timestamp >= account.lastDepositTimestamp + lockPeriod,
            "Funds are locked"
        );

        uint256 feeAmount = (amount * withdrawalFee) / 100;
        uint256 amountAfterFee = amount - feeAmount;

        account.balance -= amount;

        bool success = token.transfer(msg.sender, amountAfterFee);
        require(success, "Token transfer failed");

        emit Withdrawn(msg.sender, amount, feeAmount);
    }

    function getAccountBalance(address accountOwner)
        external
        view
        returns (uint256)
    {
        require(accounts[accountOwner].exists, "Account does not exist");
        return accounts[accountOwner].balance;
    }

    function setMinimumDeposit(uint256 _minimumDeposit) external onlyOwner {
        minimumDeposit = _minimumDeposit;
        emit MinimumDepositUpdated(_minimumDeposit);
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external onlyOwner {
        require(_withdrawalFee <= 10, "Fee cannot exceed 10%");
        withdrawalFee = _withdrawalFee;
        emit WithdrawalFeeUpdated(_withdrawalFee);
    }

    function setLockPeriod(uint256 _lockPeriod) external onlyOwner {
        lockPeriod = _lockPeriod;
        emit LockPeriodUpdated(_lockPeriod);
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        token = IERC20(_tokenAddress);
        emit TokenAddressUpdated(_tokenAddress);
    }

    function withdrawFees() external onlyOwner {
        uint256 contractBalance = token.balanceOf(address(this));
        uint256 totalUserBalances = 0;

        // This is a simplified approach and might be gas-intensive with many users
        // In a production environment, consider tracking fees separately
        address[] memory users = new address[](0); // Placeholder for actual user tracking
        for (uint256 i = 0; i < users.length; i++) {
            totalUserBalances += accounts[users[i]].balance;
        }

        uint256 fees = contractBalance - totalUserBalances;
        require(fees > 0, "No fees to withdraw");

        bool success = token.transfer(owner(), fees);
        require(success, "Token transfer failed");
    }
}
