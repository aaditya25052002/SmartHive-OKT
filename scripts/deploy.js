async function main() {
  const [deployer, feeAccount] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Assigning Fee Account with:", feeAccount.address);
  console.log("Deployer balance:", (await deployer.getBalance()).toString());
  console.log(
    "FeeAccount balance:",
    (await feeAccount.getBalance()).toString()
  );

  // Get the ContractFactories and Signers here.
  const NFT = await ethers.getContractFactory("nft");

  // deploy contracts
  const nft = await NFT.deploy(
    "SmartHive",
    "SH",
    "0xDf201019A4abd8A5386e443C051DD9eF35d37AA1"
  );

  // Save copies of each contracts abi and address to the frontend.
  saveFrontendUtils(nft, "NFT");
}

function saveFrontendUtils(contract, name) {
  const fs = require("fs");
  const utilsDir = __dirname + "./src/utils";

  if (!fs.existsSync(utilsDir)) {
    fs.mkdirSync(utilsDir);
  }

  fs.writeFileSync(
    utilsDir + `/${name}-address.json`,
    JSON.stringify({ address: contract.address }, undefined, 2)
  );

  const contractArtifact = artifacts.readArtifactSync(name);

  fs.writeFileSync(
    utilsDir + `/${name}.json`,
    JSON.stringify(contractArtifact, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
