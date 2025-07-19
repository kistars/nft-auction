const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TransferDemo", function () {

    it("upgrade contracts", async () => {

        // 部署V1
        const LogicV1 = await ethers.getContractFactory("LogicV1");
        const logicV1 = await upgrades.deployProxy(LogicV1, [], {
            kind: "uups",
            initializer: "initialize",
        });
        await logi();
        console.log("LogicV1 deployed to:", logicV1.address);

        // 使用V1
        await logicV1.setValue(42);
        console.log("Initial value:", (await logicV1.value()).toString());
        console.log("Value plus ten:", (await logicV1.getValuePlusTen()).toString());

        // 升级到V2
        const LogicV2 = await ethers.getContractFactory("LogicV2");
        const logicV2 = await upgrades.upgradeProxy(logicV1.address, LogicV2);
        console.log("Upgraded to LogicV2 at same address:", logicV2.address);

        // 使用V2新功能
        await logicV2.enableNewFeature();
        console.log("New feature enabled:", await logicV2.newFeature());
        console.log("Value multiplied by 3:", (await logicV2.getValueMultiplied(3)).toString());

    });

});