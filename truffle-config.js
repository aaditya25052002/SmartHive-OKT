require("babel-register");
require("babel-polyfill");

require("dotenv").config();
const HDWalletProvider = require("@truffle/hdwallet-provider");
const PRIVATE_KEY = process.env.PRIVATE_KEY;
// console.log(PRIVATE_KEY);
const provider_polygon = new HDWalletProvider(
  PRIVATE_KEY,
  "https://polygon-mumbai.infura.io/v3/c85a7880f2414c32abf07efa596041cf"
);

module.exports = {
  // Configure networks (Localhost, Rinkeby, etc.)
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*", // Match any network id
    },
    goerli: {
      provider: () =>
        new HDWalletProvider(
          process.env.DEPLOYER_KEY,
          process.env.ENDPOINT_URL
        ),
      network_id: 5,
      gas: 5500000,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
    mumbaimatic: {
      provider: provider_polygon,
      network_id: 80001,
      confirmations: 2,
      networkCheckTimeout: 1000000,
      timeoutBlocks: 200,
    },
  },
  contracts_directory: "./src/contracts/",
  contracts_build_directory: "./src/abis/",
  migrations_directory: "./migrations",
  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.11",
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
