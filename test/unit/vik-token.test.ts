import { ethers } from "hardhat";
import { VikToken } from "../../typechain-types";
import { log } from "console";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { assert, expect } from "chai";

describe("Vik token unit test", () => {
  const INITIAL_SUPPLY = 10000;
  let vikTokenContract: VikToken;
  let vikTokenAddress: string;
  async function deployVikToken() {
    vikTokenContract = await ethers.deployContract("VikToken", [
      INITIAL_SUPPLY,
    ]);
    vikTokenAddress = await vikTokenContract.getAddress();
    log(`Vik token deployed at ${vikTokenAddress}`);
  }

  beforeEach(async () => {
    await loadFixture(deployVikToken);
  });

  it("Deploys correctly", async () => {
    expect(vikTokenContract !== undefined).to.be.true;
    expect(vikTokenAddress !== undefined).to.be.true;
  });

  it("Initializes contract correctly", async () => {
    const name = await vikTokenContract.name();
    const symbol = await vikTokenContract.symbol();
    const totalSupply = await vikTokenContract.getInitialSupply();
    expect(name).to.equal("VikToken");
    expect(symbol).to.equal("VIK");
    expect(totalSupply).to.equal(INITIAL_SUPPLY);
  });
});
