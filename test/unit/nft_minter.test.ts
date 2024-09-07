import { ethers } from "hardhat";
import { ERC20Mock } from "../../typechain-types";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { bigint } from "hardhat/internal/core/params/argumentTypes";
import { log } from "console";

describe("NFT Minter unit test", () => {
  async function deploy() {
    const [deployer, user1, user2, user3] = await ethers.getSigners();

    const mockErc20Factory = await ethers.getContractFactory("ERC20Mock");
    const mockErc20 = await mockErc20Factory.deploy();
    await mockErc20.waitForDeployment();
    const mockErc20Address = await mockErc20.getAddress();

    const nftMinterFactory = await ethers.getContractFactory("NftMinter");
    const nftMinter = await nftMinterFactory.deploy(mockErc20Address);
    await nftMinter.waitForDeployment();
    const nftMinterAddress = await nftMinter.getAddress();
    return {
      nftMinter,
      nftMinterAddress,
      deployer,
      user1,
      user2,
      user3,
      mockErc20,
    };
  }

  it("Mocks correctly", async () => {
    const { mockErc20, deployer } = await loadFixture(deploy);
    expect(await mockErc20.balanceOf(deployer.address)).to.equal(
      ethers.parseEther("10")
    );
  });

  it("Approves correctly", async () => {
    const { mockErc20, deployer, nftMinter, nftMinterAddress } =
      await loadFixture(deploy);
    const trx = await mockErc20.approve(
      nftMinterAddress,
      ethers.parseEther("2")
    );
    await trx.wait(1);
    expect(await nftMinter.getAllownace(deployer.address)).to.equal(
      ethers.parseEther("2")
    );
  });

  it("Fails if _to is zero address", async () => {
    const { mockErc20, deployer, nftMinter, nftMinterAddress } =
      await loadFixture(deploy);
    const trx = await mockErc20.approve(
      nftMinterAddress,
      ethers.parseEther("2")
    );
    await trx.wait(1);
    await expect(
      nftMinter.mintWithToken(ethers.ZeroAddress, 1)
    ).to.be.revertedWith("Zero address");
  });

  it("Fails if there is not enough allowance", async () => {
    const { mockErc20, deployer, nftMinter, nftMinterAddress } =
      await loadFixture(deploy);
    const trx = await mockErc20.approve(
      nftMinterAddress,
      ethers.parseEther("2")
    );
    await trx.wait(1);
    await expect(
      nftMinter.mintWithToken(deployer.address, ethers.parseEther("3"))
    ).to.be.revertedWith("Not enough allowance");
  });

  it("Fails if lower than MIN_AMOUNT", async () => {
    const { mockErc20, deployer, nftMinter, nftMinterAddress } =
      await loadFixture(deploy);
    const trx = await mockErc20.approve(
      nftMinterAddress,
      ethers.parseEther("2")
    );
    await trx.wait(1);
    await expect(
      nftMinter.mintWithToken(deployer.address, ethers.parseEther("0.2"))
    ).to.be.revertedWith("Invalid amount");
  });

  it("Successfully mints nfts", async () => {
    const { mockErc20, deployer, nftMinter, nftMinterAddress } =
      await loadFixture(deploy);
    const trx = await mockErc20.approve(
      nftMinterAddress,
      ethers.parseEther("2")
    );
    await trx.wait(1);
    const trx2 = await nftMinter.mintWithToken(
      deployer.address,
      ethers.parseEther("1")
    );
    await trx2.wait(1);

    expect(await nftMinter.balanceOf(deployer.address)).to.equal(1);
    expect(await nftMinter.tokenURI(0)).to.equal("https://customdomain.com/0");

    const trx3 = await nftMinter.mintWithToken(
      deployer.address,
      ethers.parseEther("1")
    );
    await trx3.wait(1);
    expect(await nftMinter.balanceOf(deployer.address)).to.equal(2);
    expect(await nftMinter.tokenURI(1)).to.equal("https://customdomain.com/1");
  });
});
