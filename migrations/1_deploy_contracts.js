require('dotenv').config();
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

// const SLICE_ADDRESS = "0x0aee8703d34dd9ae107386d3eff22ae75dd616d1";

const SLICE_TOKEN_SUPPLY = 20000000;
const SLICE_TOKEN_MAX_CAP = 1000000000;
const REWARD_TOKEN_SUPPLY = 10000000;

const SliceToken = artifacts.require('SliceToken');
const RewardToken = artifacts.require('RewardToken');

const MultiRewards = artifacts.require('MultiRewards');

const TokenSplitter = artifacts.require('TokenSplitter');
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
    const tokenOwner = accounts[0];
    const ts1 = accounts[1];
    const ts2 = accounts[2];
    const ts3 = accounts[3];

    const SLICEinstance = await deployProxy(SliceToken, [SLICE_TOKEN_SUPPLY, SLICE_TOKEN_MAX_CAP], { from: tokenOwner });
    console.log('SLICE token Deployed: ', SLICEinstance.address);

    const rewardInstance = await deployProxy(RewardToken, [REWARD_TOKEN_SUPPLY], { from: tokenOwner });
    console.log('Reward token Deployed: ', rewardInstance.address);

    const MRinstance = await deployProxy(MultiRewards, [tokenOwner, SLICEinstance.address], { from: tokenOwner });
    console.log('MultiRewards Deployed: ', MRinstance.address);

    /*********************** */

    const TRDinstance = await deployProxy(TradingRewardsDistributor, [SLICEinstance.address], { from: tokenOwner });
    console.log('Trading Rewards Distributor Deployed: ', TRDinstance.address);

    const TSinstance = await deployProxy(TokenSplitter, [[TRDinstance.address, ts2, ts3], [4410, 800, 900], SLICEinstance.address], { from: tokenOwner });
    console.log('Token Splitter Deployed: ', TSinstance.address);

    const TDinstance = await deployProxy(TokenDistributor, [SLICEinstance.address, TSinstance.address, 1, 
          [web3.utils.toWei("189"), web3.utils.toWei("89.775"), web3.utils.toWei("35.4375"), web3.utils.toWei("18.9")], 
          [web3.utils.toWei("611"), web3.utils.toWei("290.225"), web3.utils.toWei("114.5625"), web3.utils.toWei("61.1")],
          [195000, 585000, 1560000, 2346250], 4], { from: tokenOwner });
    console.log('Token Distributor Deployed: ', TDinstance.address);

    const FSinstance = await deployProxy(FeeSharingSystem, [SLICEinstance.address, rewardInstance.address, TDinstance.address], { from: tokenOwner });
    console.log('Fee Sharing System Deployed: ', FSinstance.address);

    

  } else if (network == "kovan") {
    
  } else if (network == "mainnet") {

  }
}