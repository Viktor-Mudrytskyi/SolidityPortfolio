import getEnvConfig from "../utils/env-utils";

export interface NetworkInterface {
  name: string;
  deployName: string;
  rpcUrl?: string;
  chainId: number;
  gasPriceApi?: string;
  isLocal: boolean;
}

const {
  ethSepoliaRpc,
  polygonCardonaRpc,
  localhostRpc,
  ethSepoliaGasApi,
  polygonCardonaGasApi,
} = getEnvConfig();

export const ethSepoliaNetwork: NetworkInterface = {
  name: "Ethereum Sepolia",
  deployName: "eth-sepolia",
  rpcUrl: ethSepoliaRpc,
  gasPriceApi: ethSepoliaGasApi,
  chainId: 11155111,
  isLocal: false,
};

export const polygonCardonaNetwork: NetworkInterface = {
  name: "Polygon Cardons",
  deployName: "polygon-cardona",
  rpcUrl: polygonCardonaRpc,
  gasPriceApi: polygonCardonaGasApi,
  chainId: 2442,
  isLocal: false,
};

export const hardhatNetwork: NetworkInterface = {
  name: "Hard-Hat",
  deployName: "hardhat",
  chainId: 31337,
  isLocal: true,
};

export const localhostNetwork: NetworkInterface = {
  name: "Localhost",
  deployName: "localhost",
  chainId: 31337,
  rpcUrl: localhostRpc,
  isLocal: true,
};

export const chainIdToSupportedNetworks = {
  [ethSepoliaNetwork.chainId]: ethSepoliaNetwork,
  [polygonCardonaNetwork.chainId]: polygonCardonaNetwork,
  [hardhatNetwork.chainId]: hardhatNetwork,
  [localhostNetwork.chainId]: localhostNetwork,
};
