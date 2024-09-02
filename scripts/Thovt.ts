import { ethers } from "hardhat";

const name = "Thovt"
const symbol = "THOVT"
const totalSupply =  ethers.parseEther("500000000") 
const treasury = "0x7FDabB3689823A196228DC7e5cd8d84Dd3b37003"
const operator = "0x9D042D9dC4E0DA1d87e43469e35b3Dae95A49331" 
const token = "0x8AE75C88Caded968C60F0d5e917c936c6AAbFdee"

async function main() {
  

  // ethers is available in the global scope
  const [deployer] = await ethers.getSigners();
//   console.log(deployer.address)  
  const token = await ethers.deployContract("ThovtToken", [name, symbol, totalSupply,treasury, operator])
    await token.waitForDeployment()
    console.log(await token.getAddress())
  

  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });