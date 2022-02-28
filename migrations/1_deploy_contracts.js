require('dotenv').config();
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

const SLICE_ADDRESS = "0x0aee8703d34dd9ae107386d3eff22ae75dd616d1";

const MultiRewards = artifacts.require('MultiRewards');

const FeeSharingSystem = artifacts.require('FeeSharingSystem');
const TokenDistributor = artifacts.require('TokenDistributor');
const TradingRewardsDistributor = artifacts.require('TradingRewardsDistributor');

// const AdminTools = "0x8532477A282DA1f68BB49F0893714e10F03d6186";
// const FeesCollector = "0x16d7dFBa832722F240915e63198e411153AC602b"; 
// const TranchesDeployer = "0x8cae1786645184BBc9078e50CeD90ac9eE0b3ADE";
// const JCompoundAddress = "0x05060F5ab3e7A98E180B418A96fFc82A85b115e7";
// const JCHelper = "0x8a0c35A0241Cc04e075aaad3F501585d3b2a6dD5";

module.exports = async (deployer, network, accounts) => {

  if (network == "development") {
    const factoryOwner = accounts[0];

    await deployer.deploy(MultiRewards, factoryOwner, SLICE_ADDRESS);
    const MRinstance = await MultiRewards.deployed();
    console.log('MultiRewards Deployed: ', MRinstance.address);

    await deployer.deploy(TokenDistributor, SLICE_ADDRESS, SLICE_ADDRESS, TokenDistrAddress);
    const TDinstance = await TokenDistributor.deployed();
    console.log('Token Distributor Deployed: ', TDinstance.address);

    await deployer.deploy(FeeSharingSystem, SLICE_ADDRESS, SLICE_ADDRESS, TDinstance.address);
    const MRinstance = await MultiRewards.deployed();
    console.log('Fee Sharing System Deployed: ', MRinstance.address);

  } else if (network == "kovan") {
    
  } else if (network == "mainnet") {

  }
}