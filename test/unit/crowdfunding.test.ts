import { ethers } from "hardhat";
import {
  Crowdfunding,
  Governance,
  GovernanceToken,
} from "../../typechain-types";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { bigint } from "hardhat/internal/core/params/argumentTypes";
import { log } from "console";

describe("Crowdfunding unit test", () => {
  const oneEth = ethers.parseEther("1");
  const oneOverThEth = ethers.parseEther("0.001");

  async function deploy() {
    const [deployer, user1, user2, user3] = await ethers.getSigners();
    const crowdFundngFactory = await ethers.getContractFactory("Crowdfunding");

    const crowdFunding = await crowdFundngFactory.deploy();
    await crowdFunding.waitForDeployment();
    const crowdFundingAddress = await crowdFunding.getAddress();
    return { crowdFunding, crowdFundingAddress, deployer, user1, user2, user3 };
  }

  async function createProject(
    creator: HardhatEthersSigner,
    crowdFunding: Crowdfunding,
    name: string,
    description: string,
    fundingAmount: bigint
  ): Promise<string> {
    return new Promise(async (resolve, reject) => {
      try {
        const crowdFundingConnectedCreator = crowdFunding.connect(creator);
        crowdFundingConnectedCreator.on(
          crowdFundingConnectedCreator.filters[
            "ProjectCreated(bytes32,address)"
          ],
          async () => {
            try {
              const events = await crowdFundingConnectedCreator.queryFilter(
                crowdFundingConnectedCreator.filters.ProjectCreated,
                -1
              );

              const projectId = events[events.length - 1].args[0];

              const project = await crowdFundingConnectedCreator.allProjectsMap(
                projectId
              );

              expect(project.creator).to.equal(creator.address);
              expect(project.projectName).to.equal(name);
              expect(project.projectDescription).to.equal(description);
              expect(project.projectFundingGoal).to.equal(oneEth);
              expect(project.uid).to.equal(projectId);
              expect(project.projectStatus).to.equal(0);
              resolve(projectId);
            } catch (e) {
              reject(e);
            }
          }
        );

        const createResp = await crowdFundingConnectedCreator.createProject(
          name,
          description,
          fundingAmount
        );
        await createResp.wait(1);
      } catch (e) {
        reject(e);
      }
    });
  }

  describe("Creation tests", async () => {
    it("Successfully creates Project", async () => {
      const { crowdFunding, user1, user2, user3 } = await loadFixture(deploy);
      const project1Id = await createProject(
        user1,
        crowdFunding,
        "test1",
        "desc1",
        oneEth
      );
      expect((await crowdFunding.allProjects(0))[0]).to.equal(project1Id);
      const project2Id = await createProject(
        user2,
        crowdFunding,
        "test2",
        "desc2",
        oneEth
      );
      expect((await crowdFunding.allProjects(1))[0]).to.equal(project2Id);
      const project3Id = await createProject(
        user3,
        crowdFunding,
        "test3",
        "desc3",
        oneEth
      );
      expect((await crowdFunding.allProjects(2))[0]).to.equal(project3Id);
    });

    it("Cant create one project multiple times", async () => {
      const { crowdFunding, user1, user2 } = await loadFixture(deploy);
      const projectId = await createProject(
        user1,
        crowdFunding,
        "test1",
        "desc1",
        oneEth
      );

      await expect(createProject(user2, crowdFunding, "test1", "desc1", oneEth))
        .to.be.revertedWithCustomError(crowdFunding, "ProjectAlreadyExists")
        .withArgs(projectId);
    });

    it("Validates input", async () => {
      const { crowdFunding, user1 } = await loadFixture(deploy);
      await expect(
        createProject(user1, crowdFunding, "", "desc1", oneEth)
      ).to.be.revertedWithCustomError(crowdFunding, "CreationInvalidData");

      await expect(
        createProject(user1, crowdFunding, "1", "", oneEth)
      ).to.be.revertedWithCustomError(crowdFunding, "CreationInvalidData");

      await expect(
        createProject(user1, crowdFunding, "title", "desc1", BigInt(0))
      ).to.be.revertedWithCustomError(crowdFunding, "CreationInvalidData");
    });
  });

  describe("Funding tests", async () => {
    it("Correctly funds projects and emits corresponding event", async () => {
      const { crowdFunding, user1 } = await loadFixture(deploy);

      await new Promise(async (resolve, reject) => {
        try {
          crowdFunding.on(crowdFunding.filters.ProjectFunded, async () => {
            try {
              const events = await crowdFunding.queryFilter(
                crowdFunding.filters.ProjectFunded,
                -1
              );

              const projectId = events[events.length - 1].args[0];
              const sender = events[events.length - 1].args[1];
              const valueSent = events[events.length - 1].args[2];

              expect(projectId).to.equal(project1Id);
              expect(sender).to.equal(user1.address);
              expect(valueSent).to.equal(oneOverThEth);

              const contribution = await crowdFunding.contributorsMap(
                project1Id,
                user1.address
              );

              expect(contribution).to.equal(oneOverThEth);

              const project1Funding = await crowdFunding.fundingMap(project1Id);

              expect(project1Funding).to.equal(oneOverThEth);

              resolve("");
            } catch (e) {
              reject(e);
            }
          });

          const project1Id = await createProject(
            user1,
            crowdFunding,
            "test1",
            "desc1",
            oneEth
          );

          const user1CrowdFunding = crowdFunding.connect(user1);
          const contributePr1Resp = await user1CrowdFunding.contribute(
            project1Id,
            {
              value: oneOverThEth,
            }
          );

          await contributePr1Resp.wait(1);
        } catch (e) {
          reject(e);
        }
      });
    });

    it("Cant fund more than funding goal", async () => {
      const { crowdFunding, user1 } = await loadFixture(deploy);
      const project1Id = await createProject(
        user1,
        crowdFunding,
        "test1",
        "desc1",
        oneEth
      );

      const user1CrowdFunding = crowdFunding.connect(user1);
      const user1BalBef = await ethers.provider.getBalance(user1.address);

      const contributePr1Resp = await user1CrowdFunding.contribute(project1Id, {
        value: oneEth + oneEth,
      });

      const contributePr1Receipt = await contributePr1Resp.wait(1);

      const user1BalAfter = await ethers.provider.getBalance(user1.address);

      expect(
        user1BalBef -
          oneEth -
          BigInt(contributePr1Receipt?.gasUsed ?? 0) *
            BigInt(contributePr1Receipt?.gasPrice ?? 0)
      ).to.equal(user1BalAfter);

      const contribution = await crowdFunding.contributorsMap(
        project1Id,
        user1.address
      );

      expect(contribution).to.equal(oneEth);

      const project1Funding = await crowdFunding.fundingMap(project1Id);

      expect(project1Funding).to.equal(oneEth);
    });

    it("Cant fund project that doesnt exist", async () => {
      const { crowdFunding, user1 } = await loadFixture(deploy);
      const fakeProjectId = await ethers.keccak256(ethers.randomBytes(32));

      const user1CrowdFunding = crowdFunding.connect(user1);

      await expect(
        user1CrowdFunding.contribute(fakeProjectId, {
          value: oneEth,
        })
      )
        .to.be.revertedWithCustomError(crowdFunding, "ProjectDoesntExist")
        .withArgs(fakeProjectId);
    });
  });
});
