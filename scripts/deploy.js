const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  const signers = await hre.ethers.getSigners();
  const [owner, seller, buyer] = signers;
  // console.log(owner?.address,seller?.address,buyer?.address,"signers-------------");

  const MarketplaceFactory = await ethers.getContractFactory("Marketplace");
  // console.log(MarketplaceFactory, "MarketplaceFactory");
  const marketplace = await MarketplaceFactory.connect(owner).deploy();
  // console.log(marketplace, "marketplace");
  await marketplace.waitForDeployment();
  const marketplaceAddress = await marketplace.getAddress();

  const listTx = await marketplace
    .connect(seller)
    .listProduct(
      "Goood Product",
      "This is the best shampooo",
      ethers.parseEther("1.5")
    );
  await listTx.wait();
  const productId = await marketplace.getProductCount();
  const product = await marketplace.getProduct(productId);
  console.log(`Product ${productId} listed by ${seller.address}:`, product);

  const buyTx = await marketplace
    .connect(buyer)
    .buyProduct(productId, { value: ethers.parseEther("1.6") });
  await buyTx.wait();
  console.log(`Product ${productId} bought by ${buyer.address}`);

  const orderId = await marketplace.getOrderCount();
  const order = await marketplace.getOrder(orderId);
  console.log(`Order ${orderId} created by ${buyer.address}:`, order);
  
  const updatedProduct = await marketplace.getProduct(productId);
  console.log(`Updated Product ${productId}:`, updatedProduct);

  try {
    const buyAgainTx = await marketplace.connect(buyer).buyProduct(productId, {
      value: ethers.parseEther("1.6"),
    });
    await buyAgainTx.wait();
    console.log("Second purchase succeeded (this should not happen)");
  } catch (error) {
    console.log("Attempt to buy again failed as expected:", error.message);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
