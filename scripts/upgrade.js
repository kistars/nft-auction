// scripts/upgrade.js
const { ethers, upgrades } = require("hardhat");

async function main() {
    const proxyAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
    const MyContractV2 = await ethers.getContractFactory("NFTAuctionV2");

    const upgraded = await upgrades.upgradeProxy(proxyAddress, MyContractV2);
    console.log("Upgraded proxy to V2 at:", await upgraded.getAddress());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
