const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TransferDemo", function () {
    let token, demo, owner, user, tokenAddr, demoAddr;

    beforeEach(async () => {
        [owner, user] = await ethers.getSigners();

        const Token = await ethers.getContractFactory("TestToken");
        token = await Token.deploy();
        await token.waitForDeployment();
        tokenAddr = await token.getAddress();

        //
        const Demo = await ethers.getContractFactory("TransferDemo");
        demo = await Demo.deploy(tokenAddr);
        await demo.waitForDeployment();
        demoAddr = await demo.getAddress();

        // await
        await token.transfer(demoAddr, ethers.parseEther("100"));
    });

    it("若合约没钱则转账失败", async () => {
        await demo.transferToken(ethers.parseEther("100"));

        await expect(demo.transferToken(ethers.parseEther("1"))).to.be.reverted;
    });


    it("确认 transfer 调用者是合约", async () => {
        // 这个信息不能直接在 JS 中看调用者
        // 但我们知道只有合约持有 token，owner 没有授权
        // 所以 transfer 能成功，只可能是合约发起的
        await demo.transferToken(ethers.parseEther("5"));
        const balance = await token.balanceOf(owner.address);
        expect(balance).to.equal(ethers.parseEther("5"));
    });
});