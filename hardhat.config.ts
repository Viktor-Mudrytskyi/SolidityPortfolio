import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-network-helpers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@typechain/hardhat";
import * as dotenv from "dotenv";
import getEnvConfig from "./utils/env-utils";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "@nomicfoundation/hardhat-ignition-ethers";

dotenv.config();

const {
  privateKey,
  etherscanApiKey,
  coinmarketCapApiKey,
  ethSepoliaGasPriceApi,
} = getEnvConfig();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.24",
      },
      {
        version: "0.8.20",
      },
    ],
  },
  mocha: {
    timeout: 4000000,
  },
  gasReporter: {
    enabled: false,
    currency: "USD",
    coinmarketcap: coinmarketCapApiKey,
    gasPriceApi: ethSepoliaGasPriceApi, // ETH Sepolia gas price
  },
  etherscan: {
    apiKey: etherscanApiKey,
  },
};

export default config;
