// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { ChainId, Token, WAVAX } from "@pangolindex/sdk";

export const FACTORY_ADDRESS = {
  [ChainId.FUJI]: "0x12c643591dD4bcf68bc71Ff5d79DB505EaC792A2",
  [ChainId.AVALANCHE]: "0xefa94DE7a4656D787667C749f7E1223D71E9FD88",
};

const STABLE_TOKEN = {
  [ChainId.FUJI]: new Token(
    ChainId.FUJI,
    "0x2058ec2791dD28b6f67DB836ddf87534F4Bbdf22",
    6,
    "FUJISTABLE",
    "The Fuji stablecoin"
  ),
  [ChainId.AVALANCHE]: new Token(
    ChainId.AVALANCHE,
    "0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664",
    6,
    "USDC.e",
    "USDC.e"
  ),
};

const BASE_USD_PRICE = 20;

async function main() {
  const CalculatePrice = await ethers.getContractFactory("CalculatePrice");
  const priceCalculator = await CalculatePrice.deploy(
    WAVAX[ChainId.AVALANCHE].address,
    STABLE_TOKEN[ChainId.AVALANCHE].address,
    FACTORY_ADDRESS[ChainId.AVALANCHE],
    BASE_USD_PRICE
  );

  await priceCalculator.deployed();

  console.log("Price calculator deployed to: ", priceCalculator.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
