export default function getEnvConfig() {
  const privateKey = process.env.PRIVATE_KEY;
  const etherscanApiKey = process.env.ETHERSCAN_API_KEY;
  const coinmarketCapApiKey = process.env.COIMARKETCAP_API_KEY;
  const ethSepoliaGasPriceApi = process.env.SEPOLIA_ETH_GAS_PRICE_API;
  if (
    !privateKey ||
    !etherscanApiKey ||
    !coinmarketCapApiKey ||
    !ethSepoliaGasPriceApi
  ) {
    throw new Error("Missing env variables");
  }
  return {
    privateKey,
    etherscanApiKey,
    coinmarketCapApiKey,
    ethSepoliaGasPriceApi,
  };
}
