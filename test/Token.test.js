const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ERC-3643 Token", function () {
  let token, identityRegistry, compliance, claimTopicsRegistry, trustedIssuersRegistry, identityRegistryStorage;
  let owner, agent, investor1, investor2, nonInvestor;

  beforeEach(async function () {
    [owner, agent, investor1, investor2, nonInvestor] = await ethers.getSigners();

    // Deploy registries
    const ClaimTopicsRegistry = await ethers.getContractFactory("ClaimTopicsRegistry");
    claimTopicsRegistry = await ClaimTopicsRegistry.deploy();
    await claimTopicsRegistry.waitForDeployment();

    const TrustedIssuersRegistry = await ethers.getContractFactory("TrustedIssuersRegistry");
    trustedIssuersRegistry = await TrustedIssuersRegistry.deploy();
    await trustedIssuersRegistry.waitForDeployment();

    const IdentityRegistryStorage = await ethers.getContractFactory("IdentityRegistryStorage");
    identityRegistryStorage = await IdentityRegistryStorage.deploy();
    await identityRegistryStorage.waitForDeployment();

    const IdentityRegistry = await ethers.getContractFactory("IdentityRegistry");
    identityRegistry = await IdentityRegistry.deploy(
      await trustedIssuersRegistry.getAddress(),
      await claimTopicsRegistry.getAddress(),
      await identityRegistryStorage.getAddress()
    );
    await identityRegistry.waitForDeployment();

    // Grant identity registry agent role on storage
    await identityRegistryStorage.addAgentOnIdentityRegistryStorage(await identityRegistry.getAddress());

    // Deploy compliance
    const BasicCompliance = await ethers.getContractFactory("BasicCompliance");
    compliance = await BasicCompliance.deploy();
    await compliance.waitForDeployment();

    // Deploy token
    const Token = await ethers.getContractFactory("Token");
    token = await Token.deploy(
      await identityRegistry.getAddress(),
      await compliance.getAddress(),
      "Tokenized Security",
      "TSEC",
      18,
      ethers.ZeroAddress
    );
    await token.waitForDeployment();

    // Bind compliance to token
    await compliance.bindToken(await token.getAddress());

    // Setup agents
    await token.addAgentOnTokenContract(agent.address);
    await identityRegistry.addAgentOnIdentityRegistryContract(agent.address);

    // Register investors
    await identityRegistry.connect(agent).registerIdentity(investor1.address, investor1.address, 1);
    await identityRegistry.connect(agent).registerIdentity(investor2.address, investor2.address, 1);
  });

  describe("Deployment", function () {
    it("Should have correct name and symbol", async function () {
      expect(await token.name()).to.equal("Tokenized Security");
      expect(await token.symbol()).to.equal("TSEC");
    });

    it("Should have correct decimals", async function () {
      expect(await token.decimals()).to.equal(18);
    });

    it("Should have correct version", async function () {
      expect(await token.version()).to.equal("4.0");
    });

    it("Should have correct identity registry", async function () {
      expect(await token.identityRegistry()).to.equal(await identityRegistry.getAddress());
    });

    it("Should have correct compliance", async function () {
      expect(await token.compliance()).to.equal(await compliance.getAddress());
    });
  });

  describe("Minting", function () {
    it("Should allow agent to mint to verified investor", async function () {
      await token.connect(agent).mint(investor1.address, 1000);
      expect(await token.balanceOf(investor1.address)).to.equal(1000);
    });

    it("Should reject minting to non-verified address", async function () {
      await expect(
        token.connect(agent).mint(nonInvestor.address, 1000)
      ).to.be.revertedWith("Token: investor is not verified");
    });

    it("Should reject minting from non-agent", async function () {
      await expect(
        token.connect(owner).mint(investor1.address, 1000)
      ).to.be.revertedWith("AgentRole: caller is not an agent");
    });

    it("Should reject minting when paused", async function () {
      await token.connect(agent).pause();
      await expect(
        token.connect(agent).mint(investor1.address, 1000)
      ).to.be.revertedWith("Pausable: paused");
    });

    it("Should batch mint to multiple verified investors", async function () {
      await token.connect(agent).batchMint(
        [investor1.address, investor2.address],
        [1000, 2000]
      );
      expect(await token.balanceOf(investor1.address)).to.equal(1000);
      expect(await token.balanceOf(investor2.address)).to.equal(2000);
    });
  });

  describe("Transfers", function () {
    beforeEach(async function () {
      await token.connect(agent).mint(investor1.address, 1000);
    });

    it("Should allow transfer between verified investors", async function () {
      await token.connect(investor1).transfer(investor2.address, 500);
      expect(await token.balanceOf(investor1.address)).to.equal(500);
      expect(await token.balanceOf(investor2.address)).to.equal(500);
    });

    it("Should reject transfer to non-verified address", async function () {
      await expect(
        token.connect(investor1).transfer(nonInvestor.address, 500)
      ).to.be.revertedWith("Token: receiver is not verified");
    });

    it("Should reject transfer when paused", async function () {
      await token.connect(agent).pause();
      await expect(
        token.connect(investor1).transfer(investor2.address, 500)
      ).to.be.revertedWith("Pausable: paused");
    });

    it("Should allow forced transfer by agent", async function () {
      await token.connect(agent).forcedTransfer(investor1.address, investor2.address, 500);
      expect(await token.balanceOf(investor1.address)).to.equal(500);
      expect(await token.balanceOf(investor2.address)).to.equal(500);
    });
  });

  describe("Burning", function () {
    beforeEach(async function () {
      await token.connect(agent).mint(investor1.address, 1000);
    });

    it("Should allow agent to burn tokens", async function () {
      await token.connect(agent).burn(investor1.address, 500);
      expect(await token.balanceOf(investor1.address)).to.equal(500);
    });

    it("Should reject burn from non-agent", async function () {
      await expect(
        token.connect(owner).burn(investor1.address, 500)
      ).to.be.revertedWith("AgentRole: caller is not an agent");
    });
  });

  describe("Freezing", function () {
    beforeEach(async function () {
      await token.connect(agent).mint(investor1.address, 1000);
    });

    it("Should allow agent to freeze an address", async function () {
      await token.connect(agent).setAddressFrozen(investor1.address, true);
      expect(await token.isFrozen(investor1.address)).to.equal(true);
    });

    it("Should reject transfer from frozen address", async function () {
      await token.connect(agent).setAddressFrozen(investor1.address, true);
      await expect(
        token.connect(investor1).transfer(investor2.address, 500)
      ).to.be.revertedWith("Token: wallet is frozen");
    });

    it("Should allow partial token freezing", async function () {
      await token.connect(agent).freezePartialTokens(investor1.address, 300);
      expect(await token.getFrozenTokens(investor1.address)).to.equal(300);
    });

    it("Should reject transfer exceeding unfrozen balance", async function () {
      await token.connect(agent).freezePartialTokens(investor1.address, 700);
      await expect(
        token.connect(investor1).transfer(investor2.address, 500)
      ).to.be.revertedWith("Token: insufficient unfrozen balance");
    });

    it("Should allow unfreezing partial tokens", async function () {
      await token.connect(agent).freezePartialTokens(investor1.address, 300);
      await token.connect(agent).unfreezePartialTokens(investor1.address, 100);
      expect(await token.getFrozenTokens(investor1.address)).to.equal(200);
    });
  });

  describe("Pause", function () {
    it("Should allow agent to pause", async function () {
      await token.connect(agent).pause();
      expect(await token.paused()).to.equal(true);
    });

    it("Should allow agent to unpause", async function () {
      await token.connect(agent).pause();
      await token.connect(agent).unpause();
      expect(await token.paused()).to.equal(false);
    });

    it("Should reject pause from non-agent", async function () {
      await expect(
        token.connect(owner).pause()
      ).to.be.revertedWith("AgentRole: caller is not an agent");
    });
  });

  describe("Identity Registry", function () {
    it("Should correctly identify verified investors", async function () {
      expect(await identityRegistry.isVerified(investor1.address)).to.equal(true);
      expect(await identityRegistry.isVerified(nonInvestor.address)).to.equal(false);
    });

    it("Should allow deregistering identity", async function () {
      await identityRegistry.connect(agent).deleteIdentity(investor1.address);
      expect(await identityRegistry.contains(investor1.address)).to.equal(false);
    });

    it("Should allow batch registering identities", async function () {
      const [, , , , , newInvestor1, newInvestor2] = await ethers.getSigners();
      await identityRegistry.connect(agent).batchRegisterIdentity(
        [newInvestor1.address, newInvestor2.address],
        [newInvestor1.address, newInvestor2.address],
        [1, 2]
      );
      expect(await identityRegistry.isVerified(newInvestor1.address)).to.equal(true);
      expect(await identityRegistry.isVerified(newInvestor2.address)).to.equal(true);
    });
  });
});
