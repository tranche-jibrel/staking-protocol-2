require('dotenv').config();
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

// const SLICE_ADDRESS = "0x0aee8703d34dd9ae107386d3eff22ae75dd616d1";

const SLICE_TOKEN_SUPPLY = 20000000;
const REWARD_TOKEN_SUPPLY = 10000000;

const SliceToken = artifacts.require('SliceToken');
const RewardToken = artifacts.require('RewardToken');

const MultiRewards = artifacts.require('MultiRewards');

const JFeesCollector = artifacts.require('JFeesCollector');
const JAdminTools = artifacts.require('JAdminTools');

// const AdminTools = "0x8532477A282DA1f68BB49F0893714e10F03d6186";
// const FeesCollector = "0x16d7dFBa832722F240915e63198e411153AC602b"; 
// const TranchesDeployer = "0x8cae1786645184BBc9078e50CeD90ac9eE0b3ADE";
// const JCompoundAddress = "0x05060F5ab3e7A98E180B418A96fFc82A85b115e7";
// const JCHelper = "0x8a0c35A0241Cc04e075aaad3F501585d3b2a6dD5";

module.exports = async (deployer, network, accounts) => {

  if (network == "development") {
    const tokenOwner = accounts[0];
    const ts1 = accounts[1];
    const ts2 = accounts[2];
    const ts3 = accounts[3];

    const SLICEinstance = await deployProxy(SliceToken, [SLICE_TOKEN_SUPPLY], { from: tokenOwner });
    console.log('SLICE token Deployed: ', SLICEinstance.address);

    const rewardInstance = await deployProxy(RewardToken, [REWARD_TOKEN_SUPPLY], { from: tokenOwner });
    console.log('Reward token Deployed: ', rewardInstance.address);

    const MRinstance = await deployProxy(MultiRewards, [tokenOwner, SLICEinstance.address], { from: tokenOwner });
    console.log('MultiRewards Deployed: ', MRinstance.address);

    /*********************** */

    const JATinstance = await deployProxy(JAdminTools, [], { from: tokenOwner });
    console.log('JAdminTools Deployed: ', JATinstance.address);

    const JFCinstance = await deployProxy(JFeesCollector, [JATinstance.address], { from: tokenOwner });
    console.log('JFeesCollector Deployed: ', JFCinstance.address);

  } else if (network == "kovan") {
    
  } else if (network == "mainnet") {

  }
}