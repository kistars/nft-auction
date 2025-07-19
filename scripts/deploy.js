// scripts/deploy.js
const { ethers, upgrades } = require("hardhat");

async function main() {
    const MyContractV1 = await ethers.getContractFactory("NFTAuctionV1");
    const proxy = await upgrades.deployProxy(MyContractV1, [], {
        initializer: "initialize",
        kind: "uups",
    });

    await proxy.waitForDeployment();
    console.log("Proxy deployed to:", await proxy.getAddress());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
