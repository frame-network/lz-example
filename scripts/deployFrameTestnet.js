// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers } = require("hardhat");

async function main() {
  const LZFrameTestnetEndpoint = "0x83c73Da98cf733B03315aFa8758834b36a195b87";
  const frameStartId = 100000;
  const CrossChainNFTFactory = await ethers.getContractFactory("FrameLayerZeroNFT_Frame");
  const CrossChainNFT = await CrossChainNFTFactory.deploy(LZFrameTestnetEndpoint, "URL");
  await CrossChainNFT.waitForDeployment();
  const deploymentAddress = await CrossChainNFT.getAddress();
  console.log("Frame testnet ----- CrossChainNFT deployed to:", deploymentAddress);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
