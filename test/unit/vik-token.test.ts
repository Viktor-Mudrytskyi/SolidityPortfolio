import { ethers } from "hardhat";
import { VikToken } from "../../typechain-types";
import { log } from "console";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { assert, expect } from "chai";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("Vik token unit test", () => {
  const INITIAL_SUPPLY = BigInt(10 ** 18);
  let vikTokenContract: VikToken;
  let vikTokenAddress: string;
  let signers: HardhatEthersSigner[];
  async function setUp() {
    vikTokenContract = await ethers.deployContract("VikToken", [
      INITIAL_SUPPLY,
    ]);
    vikTokenAddress = await vikTokenContract.getAddress();
    signers = await ethers.getSigners();
    log(`Vik token deployed at ${vikTokenAddress}`);
  }

  beforeEach(async () => {
    await loadFixture(setUp);
  });

  it("Deploys correctly", async () => {
    expect(vikTokenContract !== undefined).to.be.true;
    expect(vikTokenAddress !== undefined).to.be.true;
  });

  it("Initializes contract correctly", async () => {
    const name = await vikTokenContract.name();
    const symbol = await vikTokenContract.symbol();
    const initialSupply = await vikTokenContract.getInitialSupply();
    const totalSupply = await vikTokenContract.totalSupply();
    expect(name).to.equal("VikToken");
    expect(symbol).to.equal("VIK");
    expect(initialSupply).to.equal(INITIAL_SUPPLY);
    expect(totalSupply).to.equal(INITIAL_SUPPLY);
    const balanceOfDeployer = await vikTokenContract.balanceOf(
      signers[0].address
    );
    expect(balanceOfDeployer).to.equal(BigInt(INITIAL_SUPPLY));
  });

  it("Transfers correctly", async () => {
    const amount = BigInt(10 ** 18);
    const recipient = signers[1].address;
    const sender = signers[0].address;
    const balanceOfSenderBefore = await vikTokenContract.balanceOf(sender);
    const balanceOfRecipientBefore = await vikTokenContract.balanceOf(
      recipient
    );
    const trxResponse = await vikTokenContract.transfer(recipient, amount);
    await trxResponse.wait(1);
    const events = await vikTokenContract.queryFilter(
      vikTokenContract.filters.Transfer,
      -1
    );
    const transferEvent = events[0];
    expect(transferEvent.args[0] === sender).to.be.true;
    expect(transferEvent.args[1] === recipient).to.be.true;
    expect(transferEvent.args[2] === amount).to.be.true;

    const balanceOfSenderAfter = await vikTokenContract.balanceOf(sender);
    const balanceOfRecipientAfter = await vikTokenContract.balanceOf(recipient);
    expect(balanceOfSenderAfter).to.equal(balanceOfSenderBefore - amount);
    expect(balanceOfRecipientAfter).to.equal(balanceOfRecipientBefore + amount);
  });

  it("Approves correctly", async () => {
    const owner = signers[0].address;
    const spender = signers[1].address;
    const spenderAllowance = BigInt(10 ** 10);

    const trxResponse = await vikTokenContract.approve(
      spender,
      spenderAllowance
    );
    await trxResponse.wait(1);
    const events = await vikTokenContract.queryFilter(
      vikTokenContract.filters.Approval,
      -1
    );
    const transferEvent = events[0];
    expect(transferEvent.args[0] === owner).to.be.true;
    expect(transferEvent.args[1] === spender).to.be.true;
    expect(transferEvent.args[2] === spenderAllowance).to.be.true;
    const allowance = await vikTokenContract.allowance(owner, spender);
    expect(allowance).to.equal(spenderAllowance);
  });
});
