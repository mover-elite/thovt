import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
  import { expect } from "chai";
  import hre, { ethers } from "hardhat";
  

const name = "Thovt"
const symbol = "THOVT"
const totalSupply =  ethers.parseEther("500000000") 
const treasury = "0x7FDabB3689823A196228DC7e5cd8d84Dd3b37003"
const operator = "0x9D042D9dC4E0DA1d87e43469e35b3Dae95A49331" 

  describe("Thovt token", function () {

    async function deployToken() {
        const token = await ethers.deployContract("ThovtToken", [name, symbol, totalSupply,treasury, operator])
        await token.waitForDeployment()
        return { token};
    }
  
    describe("Deployment", function () {

      it("Deploy deploy and set proper ownership", async function () {
        const [signer] = await ethers.getSigners()
        const { token} = await loadFixture(deployToken);
        expect(await token.totalSupply()).eq(totalSupply)
        expect(await token.name()).eq(name)
        expect(await token.symbol()).eq(symbol)
        expect(await token.operationsAddress()).eq(operator)
        expect(await token.treasuryAddress()).eq(treasury)
        expect(await token.balanceOf(signer.address)).eq(totalSupply)
      });
    })
     
    describe("Fee", function () {
        it("Should deduct fee", async function() {
            const { token} = await loadFixture(deployToken);
            const [dividendTaxRate,treasuryTaxRate, operationsTaxRate ] = await Promise.all([
                            await token.dividendTaxRate(),
                            await token.treasuryTaxRate(),
                            await token.operationsTaxRate()
                            ])
            const totalFee = dividendTaxRate + treasuryTaxRate  + operationsTaxRate
            const amountToTransfer = ethers.parseEther("1000")
            const to = ethers.Wallet.createRandom()
            await token.transfer(to.address, amountToTransfer)
            const toBalanceAfter = await token.balanceOf(to.address)
            const treasuryBalance = await token.balanceOf(treasury)
            const operatorBalance = await token.balanceOf(operator)
            const expectedReceivedAmount  = amountToTransfer -  (amountToTransfer  * totalFee/100n)
            const expectedTreasuryReceivedAmount = amountToTransfer * treasuryTaxRate/100n
            const expectedOperatorReceivedAmount  = amountToTransfer * operationsTaxRate/100n
            expect(toBalanceAfter).eq(expectedReceivedAmount)
            expect(treasuryBalance).eq(expectedTreasuryReceivedAmount)
            expect(operatorBalance).eq(expectedOperatorReceivedAmount)
            
          })
        it("Should not deduct fee", async () => {
        const {token} = await loadFixture(deployToken)
        const amountToTransfer = ethers.parseEther("1000")
        const to = ethers.Wallet.createRandom()
        await token.toggleisExcludedFromTax(to.address, true)
        const isExcluded = await token.isExcludedFromTax(to.address)
        expect(isExcluded).be.true
        await token.transfer(to.address, amountToTransfer)
        const balance = await token.balanceOf(to.address)
        expect(balance).eq(amountToTransfer)


        })
    })
    
    describe("Holders", () => {

        it("Should add address to holder list", async () => {
            const {token} = await loadFixture(deployToken)

            const to = ethers.Wallet.createRandom()
            const isHolderInit = await token.isHolder(to.address)
            await token.transfer(to.address, ethers.parseEther("100"))
            const isHolder = await token.isHolder(to.address)
            expect(isHolderInit).be.false
            expect(isHolder).to.true
        })

        it("Should remove address from holder list", async () => {
            const [_, to] = await ethers.getSigners()
            const {token} = await loadFixture(deployToken)
            // const to = ethers.Wallet.createRandom(ethers.provider)
            const to2 = ethers.Wallet.createRandom()
            await token.transfer(to.address, ethers.parseEther("100"))
            const balance = await token.balanceOf(to.address)
            await token.connect(to).transfer(to2.address, balance)
            const isHolder = await token.isHolder(to.address)
            const balAfter = await token.balanceOf(to.address)
            if(balAfter > 0) {
                expect(isHolder).be.true 
            }else{ 
                expect(isHolder).be.false
            }
            
        })
    
    })

    describe("Fee Distribution", () => {
        it("Should distribute fees", async () => {
            const [signer] = await ethers.getSigners()
            const { token} = await loadFixture(deployToken);
            const transferAmount = ethers.parseEther("100")

            const receiver  = ethers.Wallet.createRandom()
            
            await token.transfer(receiver.address, transferAmount)
            
            const receiverBalance = await token.balanceOf(receiver.address)
            const receiver2 = ethers.Wallet.createRandom()
            await token.transfer(receiver2.address, transferAmount)
            const receiver2Balance = await token.balanceOf(receiver2.address)
            const receiverBalanceAfter = await token.balanceOf(receiver.address)
            const holders = await token.totalHolders()
            const feeAmt = transferAmount * 1n / 100n
            expect(receiverBalance + feeAmt).eq(receiverBalanceAfter)
            expect(holders).eq(2n)
            const receiver3 = ethers.Wallet.createRandom()
            await token.transfer(receiver3.address, transferAmount)
            const receiverBalanceAfter3 = await token.balanceOf(receiver.address)
            const receiver2BalanceAfter = await token.balanceOf(receiver2.address)
            expect(receiverBalanceAfter3).eq(receiverBalanceAfter + feeAmt /2n)
            expect(receiver2BalanceAfter).eq(receiver2Balance + feeAmt /2n)

            // console.log(receiverBalanceAfter)

            


        })


        
    })

  
    
  });
  