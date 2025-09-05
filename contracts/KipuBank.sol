// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract KipuBank {
    uint256 public immutable bankCap; // <-- Límite global de depósitos (inmutable)
    uint256 public totalDeposits;     // <-- Balance total del contrato (para validar bankCap)

    // Contadores globales
    uint256 public totalDepositsCount;  // Total de depósitos en el contrato
    uint256 public totalWithdrawalsCount; // Total de retiros en el contrato

    struct Account {
        uint256 balance;
        uint256 lastDepositTimestamp;
        bool exists;
        uint256 depositCount;  // Contador de depósitos del usuario
        uint256 withdrawalCount; // Contador de retiros del usuario
    }

    mapping(address => Account) public accounts;
    uint256 public minimumDeposit = 100 * 10**18; // 100 tokens
    uint256 public withdrawalFee = 5; // 5% fee
    uint256 public lockPeriod = 1 days;
    uint256 immutable private MAX_WITHDRAWL_PER_TRANS = 200;

    event AccountCreated(address indexed owner);
    event Deposited(address indexed owner, uint256 amount, uint256 userDepositCount, uint256 totalDepositsCount);
    event Withdrawn(address indexed owner, uint256 amount, uint256 fee, uint256 userWithdrawalCount, uint256 totalWithdrawalsCount);
    event MinimumDepositUpdated(uint256 newMinimumDeposit);
    event WithdrawalFeeUpdated(uint256 newWithdrawalFee);
    event LockPeriodUpdated(uint256 newLockPeriod);
    event TokenAddressUpdated(address newTokenAddress);
    event BankCapSet(uint256 cap);

    error BankCapInitError(uint256 bankCap);
    error NoBalanceError(address user, uint256 balance);

    modifier withBalance() {
        if (accounts[msg.sender].balance <= 0) revert NoBalanceError(msg.sender, 0); 
        _;
    }

    constructor(uint256 _bankCap) {
        if (_bankCap < 0) revert BankCapInitError(_bankCap);
        bankCap = _bankCap;
        emit BankCapSet(_bankCap);
    }

    function createAccount() external {
        require(!accounts[msg.sender].exists, "Account already exists");

        accounts[msg.sender] = Account({
            balance: 0,
            lastDepositTimestamp: 0,
            exists: true,
            depositCount: 0,  
            withdrawalCount: 0   
        });

        emit AccountCreated(msg.sender);
    }

    function deposit(uint256 amount) external payable {
        require(accounts[msg.sender].exists, "Account does not exist");
        require(amount >= minimumDeposit, "Amount below minimum deposit");
        require(
            totalDeposits + amount <= bankCap,
            "Deposit would exceed bank capacity"
        );

        accounts[msg.sender].balance += amount;
        accounts[msg.sender].lastDepositTimestamp = block.timestamp;
        accounts[msg.sender].depositCount += 1;
        totalDeposits += amount;
        _incrementTotalDepositsCount();

        emit Deposited(msg.sender, amount, accounts[msg.sender].depositCount, totalDepositsCount);
    }

    /**
     * @dev Increments the total deposits counter by 1
     */
    function _incrementTotalDepositsCount() private {
        totalDepositsCount += 1;
    }

    function withdraw(uint256 amount) external withBalance {
        Account storage account = accounts[msg.sender];
        require(account.exists, "Account does not exist");
        require(account.balance >= amount, "Insufficient balance");
        require(amount <= MAX_WITHDRAWL_PER_TRANS, "Cannot exceed withdrawal limit");
        require(
            block.timestamp >= account.lastDepositTimestamp + lockPeriod,
            "Funds are locked"
        );

        uint256 feeAmount = (amount * withdrawalFee) / 100;
        uint256 amountAfterFee = amount - feeAmount;

        account.balance -= amount;
        account.withdrawalCount += 1;
        totalDeposits -= amount;
        _incrementTotalWithdrawlsCount();

        (bool success, ) = msg.sender.call{value: amountAfterFee}("");
        require(success, "Token transfer failed");

        emit Withdrawn(msg.sender, amount, feeAmount, account.withdrawalCount, totalWithdrawalsCount);
    }

    /**
     * @dev Increments the total deposits counter by 1
     */
    function _incrementTotalWithdrawlsCount() private {
        totalWithdrawalsCount += 1;
    }

    function getUserDepositCount(address user) external view returns (uint256) {
        require(accounts[user].exists, "Account does not exist");
        return accounts[user].depositCount;
    }

    function getUserWithdrawalCount(address user) external view returns (uint256) {
        require(accounts[user].exists, "Account does not exist");
        return accounts[user].withdrawalCount;
    }

    function getTotalDepositsCount() external view returns (uint256) {
        return totalDepositsCount;
    }

    function getTotalWithdrawalsCount() external view returns (uint256) {
        return totalWithdrawalsCount;
    }

    function getAccountBalance(address accountOwner)
        external
        view
        returns (uint256)
    {
        require(accounts[accountOwner].exists, "Account does not exist");
        return accounts[accountOwner].balance;
    }

    function setMinimumDeposit(uint256 _minimumDeposit) external {
        minimumDeposit = _minimumDeposit;
        emit MinimumDepositUpdated(_minimumDeposit);
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(_withdrawalFee <= 10, "Fee cannot exceed 10%");
        withdrawalFee = _withdrawalFee;
        emit WithdrawalFeeUpdated(_withdrawalFee);
    }

    function setLockPeriod(uint256 _lockPeriod) external {
        lockPeriod = _lockPeriod;
        emit LockPeriodUpdated(_lockPeriod);
    }

    function setTokenAddress(address _tokenAddress) external {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        emit TokenAddressUpdated(_tokenAddress);
    }

    function withdrawFees() external {
        uint256 contractBalance = msg.sender.balance;
        uint256 totalUserBalances = 0;

        // This is a simplified approach and might be gas-intensive with many users
        // In a production environment, consider tracking fees separately
        address[] memory users = new address[](0); // Placeholder for actual user tracking
        for (uint256 i = 0; i < users.length; i++) {
            totalUserBalances += accounts[users[i]].balance;
        }

        uint256 fees = contractBalance - totalUserBalances;
        require(fees > 0, "No fees to withdraw");

        (bool success, ) = msg.sender.call{value: fees}("");
        require(success, "Token transfer failed");
    }
}
