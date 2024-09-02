import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers, upgrades } from "hardhat";
import { MyNFT } from "../../typechain-types";
import { expect } from "chai";

describe("Upgradeable NFT unit test", () => {
  let signers: HardhatEthersSigner[];
  let deployer: HardhatEthersSigner;
  let myNFTProxy: MyNFT;

  async function deploy() {
    const nftFactory = await ethers.getContractFactory("MyNFT");

    myNFTProxy = (await upgrades.deployProxy(nftFactory, [], {
      initializer: "initialize",
    })) as unknown as MyNFT;
  }

  beforeEach(async () => {
    signers = await ethers.getSigners();
    deployer = signers[0];
    await loadFixture(deploy);
  });

  it("Upgrade", async () => {
    const mintTx = await myNFTProxy.safeMint(deployer.address, "test");
    await mintTx.wait(1);
    expect(await myNFTProxy.balanceOf(deployer.address)).to.equal(1);

    const myNftv2Factory = await ethers.getContractFactory("MyNFTV2");
    const myNftV2 = await upgrades.upgradeProxy(
      await myNFTProxy.getAddress(),
      myNftv2Factory
    );

    expect(await myNftV2.balanceOf(deployer.address)).to.equal(1);
    expect(await myNftV2.demo()).to.be.equal("Different functionality");
  });
});
