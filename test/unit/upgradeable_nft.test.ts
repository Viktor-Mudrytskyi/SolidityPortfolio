import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";
import { MyNFT } from "../../typechain-types";

describe("Upgradeable NFT unit test", () => {
  let signers: HardhatEthersSigner[];
  let deployer: HardhatEthersSigner;
  let myNFT: MyNFT;
  async function deploy() {
    const nftFactroey = ethers.getContractFactory("MyNFT");
  }

  beforeEach(async () => {
    signers = await ethers.getSigners();
    deployer = signers[0];
    await loadFixture(deploy);
  });
});
