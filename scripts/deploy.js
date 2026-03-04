const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // Deploy ClaimTopicsRegistry
  const ClaimTopicsRegistry = await ethers.getContractFactory("ClaimTopicsRegistry");
  const claimTopicsRegistry = await ClaimTopicsRegistry.deploy();
  await claimTopicsRegistry.waitForDeployment();
  console.log("ClaimTopicsRegistry deployed to:", await claimTopicsRegistry.getAddress());

  // Deploy TrustedIssuersRegistry
  const TrustedIssuersRegistry = await ethers.getContractFactory("TrustedIssuersRegistry");
  const trustedIssuersRegistry = await TrustedIssuersRegistry.deploy();
  await trustedIssuersRegistry.waitForDeployment();
  console.log("TrustedIssuersRegistry deployed to:", await trustedIssuersRegistry.getAddress());

  // Deploy IdentityRegistryStorage
  const IdentityRegistryStorage = await ethers.getContractFactory("IdentityRegistryStorage");
  const identityRegistryStorage = await IdentityRegistryStorage.deploy();
  await identityRegistryStorage.waitForDeployment();
  console.log("IdentityRegistryStorage deployed to:", await identityRegistryStorage.getAddress());

  // Deploy IdentityRegistry
  const IdentityRegistry = await ethers.getContractFactory("IdentityRegistry");
  const identityRegistry = await IdentityRegistry.deploy(
    await trustedIssuersRegistry.getAddress(),
    await claimTopicsRegistry.getAddress(),
    await identityRegistryStorage.getAddress()
  );
  await identityRegistry.waitForDeployment();
  console.log("IdentityRegistry deployed to:", await identityRegistry.getAddress());

  // Grant IdentityRegistry agent role on IdentityRegistryStorage
  await identityRegistryStorage.addAgentOnIdentityRegistryStorage(await identityRegistry.getAddress());

  // Deploy BasicCompliance
  const BasicCompliance = await ethers.getContractFactory("BasicCompliance");
  const compliance = await BasicCompliance.deploy();
  await compliance.waitForDeployment();
  console.log("BasicCompliance deployed to:", await compliance.getAddress());

  // Deploy Token
  const Token = await ethers.getContractFactory("Token");
  const token = await Token.deploy(
    await identityRegistry.getAddress(),
    await compliance.getAddress(),
    "Tokenized Security",
    "TSEC",
    18,
    ethers.ZeroAddress
  );
  await token.waitForDeployment();
  console.log("Token deployed to:", await token.getAddress());

  // Bind token to compliance
  await compliance.bindToken(await token.getAddress());

  // Grant deployer agent role on token and identity registry
  await token.addAgentOnTokenContract(deployer.address);
  await identityRegistry.addAgentOnIdentityRegistryContract(deployer.address);

  console.log("\nDeployment complete!");
  console.log("Token address:", await token.getAddress());
  console.log("Identity Registry:", await identityRegistry.getAddress());
  console.log("Compliance:", await compliance.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
