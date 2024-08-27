import { ethers } from "hardhat";
import { Governance, GovernanceToken } from "../../typechain-types";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { bigint } from "hardhat/internal/core/params/argumentTypes";
import { log } from "console";

describe("Governance unit test", () => {
  let govToken: GovernanceToken;
  let govTokenAddress: string;
  let governance: Governance;
  let governanceAddress: string;
  let signers: HardhatEthersSigner[];
  let deployer: HardhatEthersSigner;

  async function _init() {
    govToken = await ethers.deployContract("GovernanceToken");
    govTokenAddress = await govToken.getAddress();
    governance = await ethers.deployContract("Governance", [govTokenAddress]);
    governanceAddress = await governance.getAddress();

    signers = await ethers.getSigners();
    deployer = signers[0];
  }

  beforeEach(async () => {
    await loadFixture(_init);
  });

  describe("Governance token tests", async () => {
    const initialSupply = BigInt(10 ** 18) * BigInt(10);

    it("Token supply is correct", async () => {
      expect(await govToken.totalSupply()).to.equal(initialSupply);
      expect(await govToken.balanceOf(deployer)).to.equal(initialSupply);
    });
  });

  describe("Propose tests", async () => {});
});
