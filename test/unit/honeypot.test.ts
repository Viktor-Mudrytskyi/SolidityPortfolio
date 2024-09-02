import { ethers } from "hardhat";
import { expect } from "chai";
import { AttackBank, Bank } from "../../typechain-types";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("Honeypot unit tests", () => {
  async function deploy() {
    const [deployer, attacker] = await ethers.getSigners();

    const loggerFactory = await ethers.getContractFactory("Logger");
    const logger = await loggerFactory.deploy();
    await logger.waitForDeployment();
    const loggerAddress = await logger.getAddress();

    const honeypotFactory = await ethers.getContractFactory("Honeypot");
    const honeypot = await honeypotFactory.deploy();
    await honeypot.waitForDeployment();
    const honeypotAddress = await honeypot.getAddress();

    const honeyPotBankFactory = await ethers.getContractFactory("Bank");
    const honeyPotBank = await honeyPotBankFactory.deploy(honeypotAddress);
    await honeyPotBank.waitForDeployment();
    const honeyPotBankAddress = await honeyPotBank.getAddress();

    const honeypotAttackFactory = await ethers.getContractFactory("AttackBank");
    const honeypotAttackBank: AttackBank = await honeypotAttackFactory.deploy(
      honeyPotBankAddress
    );
    await honeypotAttackBank.waitForDeployment();
    const honeypotAttackBankAddress = await honeypotAttackBank.getAddress();

    const bankFactory = await ethers.getContractFactory("Bank");
    const bank: Bank = await bankFactory.deploy(loggerAddress);
    await bank.waitForDeployment();
    const bankAddress = await bank.getAddress();

    const attackBankFactory = await ethers.getContractFactory("AttackBank");
    const attackBank: AttackBank = await attackBankFactory.deploy(bankAddress);
    await attackBank.waitForDeployment();
    const attackBankAddress = await attackBank.getAddress();

    return {
      deployer,
      attacker,
      bank,
      honeyPotBank,
      attackBank,
      bankAddress,
      attackBankAddress,
      honeypotAttackBank,
    };
  }

  it("Attack", async () => {
    const { deployer, attacker, bank, attackBank } = await loadFixture(deploy);
    const initAmount = await ethers.parseEther("5");
    const entranceAttackAmount = await ethers.parseEther("1");
    const trx = await bank.connect(deployer).deposit({ value: initAmount });
    await trx.wait(1);

    const attack = attackBank.connect(attacker);
    const trx2 = await attack.attack({ value: entranceAttackAmount });
    await trx2.wait(1);
    expect(await bank.getBalance()).to.equal(0);
    expect(await attack.getBalance()).to.equal(
      initAmount + entranceAttackAmount
    );
  });

  it("Honeypot attacker", async () => {
    const { deployer, attacker, honeyPotBank, honeypotAttackBank } =
      await loadFixture(deploy);
    const initAmount = await ethers.parseEther("5");
    const entranceAttackAmount = await ethers.parseEther("1");
    const trx = await honeyPotBank.deposit({ value: initAmount });
    await trx.wait(1);

    expect(await honeyPotBank.getBalance()).to.equal(initAmount);
    await expect(
      honeypotAttackBank
        .connect(attacker)
        .attack({ value: entranceAttackAmount })
    ).to.be.revertedWith("Transfer failed"); // Transfer failed instead of Honeypot because of the nature of call in solidity
  });

  it("Does not honeypot regualr users", async () => {
    const { honeyPotBank, deployer } = await loadFixture(deploy);
    const initAmount = await ethers.parseEther("5");
    const trx = await honeyPotBank.deposit({ value: initAmount });
    await trx.wait(1);

    expect(await honeyPotBank.getBalance()).to.equal(initAmount);
    await expect(honeyPotBank.withdraw()).to.changeEtherBalances(
      [honeyPotBank, deployer],
      [-initAmount, initAmount]
    );
  });
});
