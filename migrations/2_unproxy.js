require('dotenv').config();
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

// const SLICE_ADDRESS = "0x0aee8703d34dd9ae107386d3eff22ae75dd616d1";

const SLICE_TOKEN_SUPPLY = 20000000;
const ERC20_TOKEN_SUPPLY = 10000000;

const SliceToken = artifacts.require('SliceToken');
const RewardToken = artifacts.require('RewardToken');
const myERC20 = artifacts.require('myERC20');

const UnERC20Proxy = artifacts.require('UnERC20Proxy');

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

    await deployer.deploy(myERC20, ERC20_TOKEN_SUPPLY);
    const ERCinstance = await myERC20.deployed();
    console.log('erc20 Deployed: ', ERCinstance.address);
    
    await deployer.deploy(UnERC20Proxy, ERCinstance.address, "0x");
    const proxyInstance = await UnERC20Proxy.deployed();
    console.log('proxy Deployed: ', proxyInstance.address);
    console.log('implementation: ', await proxyInstance.getImplementation());
    console.log('implementation: ', await proxyInstance.owner());
    // unERC20ProxyContract = await UnERC20Proxy.new(
    //     ERCinstance.address,
    //     web3.utils.asciiToHex(""),
    //     {
    //       from: accounts[0],
    //     }
    //   );

  } else if (network == "kovan") {
    
  } else if (network == "mainnet") {

  }
}