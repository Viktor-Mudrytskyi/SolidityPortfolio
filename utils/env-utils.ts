import * as dotenv from "dotenv";
dotenv.config();

export default function getEnvConfig() {
  const address = process.env.ADDRESS;
  const privateKey = process.env.PRIVATE_KEY;

  const etherscanApiKey = process.env.ETHERSCAN_API_KEY;

  const coinmarketCapApiKey = process.env.COIMARKETCAP_API_KEY;

  const ethSepoliaRpc = process.env.ETH_SEPOLIA_RPC_URL;
  const polygonCardonaRpc = process.env.POLYGON_CARDONA_RPC_URL;
  const localhostRpc = process.env.LOCALHOST_RPC_URL;

  const ethSepoliaGasApi = process.env.ETH_SEPOLIA_GAS_PRICE_API;
  const polygonCardonaGasApi = process.env.POLYGON_ZKEVM_GAS_PRICE_API;

  if (
    !privateKey ||
    !etherscanApiKey ||
    !coinmarketCapApiKey ||
    !ethSepoliaRpc ||
    !polygonCardonaRpc ||
    !localhostRpc ||
    !ethSepoliaGasApi ||
    !polygonCardonaGasApi ||
    !address
  ) {
    throw new Error("Missing env variables");
  }
  return {
    privateKey,
    address,
    etherscanApiKey,
    coinmarketCapApiKey,
    ethSepoliaRpc,
    polygonCardonaRpc,
    localhostRpc,
    ethSepoliaGasApi,
    polygonCardonaGasApi,
  };
}
