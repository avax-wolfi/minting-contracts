import { ethers } from "hardhat";

const BASE_URI = "";
const ADMIN_WALLET = "0x1e03f8cc5c853ba13b7E35c14D960DE10A688E29";
const PRICE_CALCULATOR = "0x2800f8a7F5b02EBb40cA830BE88F4101364bc50c";

async function main() {
  const Wolfi = await ethers.getContractFactory("Wolfi");
  const wolfi = await Wolfi.deploy(
    BASE_URI,
    ADMIN_WALLET,
    PRICE_CALCULATOR
  );

  await wolfi.deployed();

  console.log("WOLFI minting contract deployed to: ", wolfi.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
