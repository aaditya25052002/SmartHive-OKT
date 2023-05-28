const NFT = artifacts.require('nft')

module.exports = async function (deployer) {
  await deployer.deploy(NFT)
}
