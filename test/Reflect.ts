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

  describe("Reflect token", function () {

    async function deployToken() {
        const token = await ethers.deployContract("REFLECT")
        await token.waitForDeployment()
        return { token};
    }
  
    describe("Deployment", function () {

      it("Should deploy", async function () {
        const [signer, guy] = await ethers.getSigners()
        const { token} = await loadFixture(deployToken);
        
        const initBalance  = await token.balanceOf(signer.address)
        await token.transfer(guy.address, ethers.parseUnits("1000", 9))
        // console.log(await token)
        const newBal = await token.balanceOf(signer.address)
        console.log(ethers.parseUnits("1000", 9))
        console.log(initBalance - newBal)
        console.log(await token.totalFees())
        // await token.excludeAccount(signer.address)
        // console.log(await token.balanceOf(signer.address))
        // const totalSupploy = BigInt(10 * 10**6 * 10**9);
        // const _rTotal = (ethers.MaxUint256 - (ethers.MaxUint256 % totalSupploy))
        // console.log(_rTotal)
    });
    })
     
    
  });
  