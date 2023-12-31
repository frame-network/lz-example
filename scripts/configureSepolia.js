// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers } = require('hardhat');
const deployments = require('./deployments');

async function main() {
    const CrossChainNFTFactory = await ethers.getContractFactory(
        'CrossChainNFT'
    );
    const CrossChainNFT = await CrossChainNFTFactory.attach(
        deployments.SEPOLIA_ADDRESS
    );

    // Set sepolia trusted remote
    let trustedRemote = hre.ethers.solidityPacked(
        ['address', 'address'],
        [deployments.FRAMETESTNET_ADDRESS, deployments.SEPOLIA_ADDRESS]
    );
    await CrossChainNFT.setTrustedRemote(10222, trustedRemote);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
