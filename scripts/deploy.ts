import { ethers } from 'hardhat'

async function main() {
    // Deploy MockToken first
    const MockToken = await ethers.getContractFactory('MockToken')
    const mockToken = await MockToken.deploy()
    await mockToken.waitForDeployment()

    console.log(`MockToken deployed to: ${await mockToken.getAddress()}`)

    // Deploy KipuBank with the MockToken address
    const KipuBank = await ethers.getContractFactory('KipuBank')
    const kipuBank = await KipuBank.deploy(await mockToken.getAddress())
    await kipuBank.waitForDeployment()

    console.log(`KipuBank deployed to: ${await kipuBank.getAddress()}`)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
