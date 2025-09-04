import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Contract, Signer } from 'ethers'

describe('KipuBank', function () {
    let kipuBank: Contract
    let mockToken: Contract
    let owner: Signer
    let user1: Signer
    let user2: Signer
    let ownerAddress: string
    let user1Address: string
    let user2Address: string

    const minimumDeposit = ethers.parseEther('100')
    const depositAmount = ethers.parseEther('200')

    beforeEach(async function () {
        ;[owner, user1, user2] = await ethers.getSigners()
        ownerAddress = await owner.getAddress()
        user1Address = await user1.getAddress()
        user2Address = await user2.getAddress()

        // Deploy MockToken
        const MockToken = await ethers.getContractFactory('MockToken')
        mockToken = await MockToken.deploy()

        // Deploy KipuBank
        const KipuBank = await ethers.getContractFactory('KipuBank')
        kipuBank = await KipuBank.deploy(await mockToken.getAddress())

        // Transfer tokens to users for testing
        await mockToken.transfer(user1Address, ethers.parseEther('1000'))
        await mockToken.transfer(user2Address, ethers.parseEther('1000'))
    })

    describe('Initialization', function () {
        it('Should set the correct token address', async function () {
            expect(await kipuBank.token()).to.equal(
                await mockToken.getAddress(),
            )
        })

        it('Should set the correct owner', async function () {
            expect(await kipuBank.owner()).to.equal(ownerAddress)
        })

        it('Should set the correct minimum deposit', async function () {
            expect(await kipuBank.minimumDeposit()).to.equal(minimumDeposit)
        })
    })

    describe('Account Management', function () {
        it('Should create a new account', async function () {
            await kipuBank.connect(user1).createAccount()
            const account = await kipuBank.accounts(user1Address)
            expect(account.exists).to.be.true
            expect(account.balance).to.equal(0)
        })

        it('Should not allow creating an account twice', async function () {
            await kipuBank.connect(user1).createAccount()
            await expect(
                kipuBank.connect(user1).createAccount(),
            ).to.be.revertedWith('Account already exists')
        })
    })

    describe('Deposits', function () {
        beforeEach(async function () {
            await kipuBank.connect(user1).createAccount()
            await mockToken
                .connect(user1)
                .approve(await kipuBank.getAddress(), ethers.parseEther('1000'))
        })

        it('Should deposit tokens successfully', async function () {
            await kipuBank.connect(user1).deposit(depositAmount)
            const account = await kipuBank.accounts(user1Address)
            expect(account.balance).to.equal(depositAmount)
        })

        it('Should not allow deposits below minimum', async function () {
            await expect(
                kipuBank.connect(user1).deposit(ethers.parseEther('50')),
            ).to.be.revertedWith('Amount below minimum deposit')
        })

        it('Should not allow deposits without an account', async function () {
            await expect(
                kipuBank.connect(user2).deposit(depositAmount),
            ).to.be.revertedWith('Account does not exist')
        })
    })

    describe('Withdrawals', function () {
        beforeEach(async function () {
            await kipuBank.connect(user1).createAccount()
            await mockToken
                .connect(user1)
                .approve(await kipuBank.getAddress(), ethers.parseEther('1000'))
            await kipuBank.connect(user1).deposit(depositAmount)
        })

        it('Should not allow withdrawals during lock period', async function () {
            await expect(
                kipuBank.connect(user1).withdraw(depositAmount),
            ).to.be.revertedWith('Funds are locked')
        })

        it('Should allow withdrawals after lock period', async function () {
            // Advance time by more than the lock period (1 day)
            await ethers.provider.send('evm_increaseTime', [86401]) // 1 day + 1 second
            await ethers.provider.send('evm_mine', [])

            const withdrawAmount = ethers.parseEther('100')
            const feeAmount = (withdrawAmount * BigInt(5)) / BigInt(100) // 5% fee
            const expectedTransfer = withdrawAmount - feeAmount

            const balanceBefore = await mockToken.balanceOf(user1Address)
            await kipuBank.connect(user1).withdraw(withdrawAmount)
            const balanceAfter = await mockToken.balanceOf(user1Address)

            expect(balanceAfter - balanceBefore).to.equal(expectedTransfer)

            const account = await kipuBank.accounts(user1Address)
            expect(account.balance).to.equal(depositAmount - withdrawAmount)
        })
    })

    describe('Admin Functions', function () {
        it('Should allow owner to update minimum deposit', async function () {
            const newMinimumDeposit = ethers.parseEther('150')
            await kipuBank.connect(owner).setMinimumDeposit(newMinimumDeposit)
            expect(await kipuBank.minimumDeposit()).to.equal(newMinimumDeposit)
        })

        it('Should allow owner to update withdrawal fee', async function () {
            const newFee = 7 // 7%
            await kipuBank.connect(owner).setWithdrawalFee(newFee)
            expect(await kipuBank.withdrawalFee()).to.equal(newFee)
        })

        it('Should not allow setting fee above 10%', async function () {
            await expect(
                kipuBank.connect(owner).setWithdrawalFee(11),
            ).to.be.revertedWith('Fee cannot exceed 10%')
        })

        it('Should allow owner to update lock period', async function () {
            const newLockPeriod = 2 * 86400 // 2 days
            await kipuBank.connect(owner).setLockPeriod(newLockPeriod)
            expect(await kipuBank.lockPeriod()).to.equal(newLockPeriod)
        })
    })
})
