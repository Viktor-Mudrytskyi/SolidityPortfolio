import { ethers } from "hardhat";
import {
  ReentranceAttack,
  ReentranceAuction,
  ReentranceProofAuction,
} from "../../typechain-types";
import { log } from "console";
import { expect } from "chai";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("Reentrance attack test", () => {
  let bidder1: HardhatEthersSigner;
  let bidder2: HardhatEthersSigner;
  let attacker: HardhatEthersSigner;
  let deployer: HardhatEthersSigner;
  let auctionContract: ReentranceAuction;
  let attackContract: ReentranceAttack;

  let addressAuction: string;
  let addressAttack: string;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    bidder1 = signers[1];
    bidder2 = signers[2];
    attacker = signers[3];

    auctionContract = await ethers.deployContract("ReentranceAuction");
    addressAuction = await auctionContract.getAddress();
    attackContract = await ethers.deployContract("ReentranceAttack", [
      addressAuction,
    ]);

    addressAttack = await attackContract.getAddress();
  });

  it("Reentrance attack", async () => {
    const trx1 = await auctionContract
      .connect(bidder1)
      .bid({ value: ethers.parseEther("5") });

    await trx1.wait(1);

    const trx2 = await auctionContract
      .connect(bidder2)
      .bid({ value: ethers.parseEther("2") });

    await trx2.wait(1);

    const attack = attackContract.connect(attacker);
    const trx3 = await attack.proxyBid({ value: ethers.parseEther("1") });

    await trx3.wait(1);

    log(
      "Auction balance before attack",
      await ethers.provider.getBalance(addressAuction)
    );
    log("Attacker balance", await ethers.provider.getBalance(addressAttack));
    const trx4 = await attack.attack();

    await trx4.wait(1);

    log(
      "Auction balance after attack",
      await ethers.provider.getBalance(addressAuction)
    );
    log(
      "Attacker contract balance",
      await ethers.provider.getBalance(addressAttack)
    );
  });
});

describe("Reentrance proof attack test", () => {
  let bidder1: HardhatEthersSigner;
  let bidder2: HardhatEthersSigner;
  let attacker: HardhatEthersSigner;
  let deployer: HardhatEthersSigner;
  let auctionContract: ReentranceProofAuction;
  let attackContract: ReentranceAttack;

  let addressAuction: string;
  let addressAttack: string;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    bidder1 = signers[1];
    bidder2 = signers[2];
    attacker = signers[3];

    auctionContract = await ethers.deployContract("ReentranceProofAuction");
    addressAuction = await auctionContract.getAddress();
    attackContract = await ethers.deployContract("ReentranceAttack", [
      addressAuction,
    ]);

    addressAttack = await attackContract.getAddress();
  });

  it("Reentrance attack", async () => {
    const trx1 = await auctionContract
      .connect(bidder1)
      .bid({ value: ethers.parseEther("5") });

    await trx1.wait(1);

    const trx2 = await auctionContract
      .connect(bidder2)
      .bid({ value: ethers.parseEther("2") });

    await trx2.wait(1);

    const attack = attackContract.connect(attacker);
    const trx3 = await attack.proxyBid({ value: ethers.parseEther("1") });

    await trx3.wait(1);

    await expect(attack.attack()).to.be.reverted;
  });
});
