import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-network-helpers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@typechain/hardhat";
import getEnvConfig from "./utils/env-utils";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "@nomicfoundation/hardhat-ignition-ethers";
import {
  ethSepoliaNetwork,
  hardhatNetwork,
  localhostNetwork,
  polygonCardonaNetwork,
} from "./config/networks";

const { etherscanApiKey, coinmarketCapApiKey, ethSepoliaGasApi, privateKey } =
  getEnvConfig();

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
  networks: {
    [hardhatNetwork.deployName]: {
      chainId: hardhatNetwork.chainId,
    },
    [localhostNetwork.deployName]: {
      chainId: localhostNetwork.chainId,
      url: localhostNetwork.rpcUrl,
    },
    [ethSepoliaNetwork.deployName]: {
      chainId: ethSepoliaNetwork.chainId,
      url: ethSepoliaNetwork.rpcUrl,
      accounts: [privateKey],
    },
    [polygonCardonaNetwork.deployName]: {
      chainId: polygonCardonaNetwork.chainId,
      url: polygonCardonaNetwork.rpcUrl,
      accounts: [privateKey],
    },
  },
  gasReporter: {
    enabled: false,
    currency: "USD",
    coinmarketcap: coinmarketCapApiKey,
    gasPriceApi: ethSepoliaGasApi, // ETH Sepolia gas price
  },
  etherscan: {
    apiKey: etherscanApiKey,
  },
};

export default config;
