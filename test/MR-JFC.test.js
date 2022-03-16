require("dotenv").config();
const { expect } = require("chai");
const {
  BN,
  constants,
  ether,
  time,
  balance,
  expectEvent,
  expectRevert
} = require('@openzeppelin/test-helpers');

const Web3 = require('web3');
// Ganache UI on 8545
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

const timeMachine = require('ganache-time-traveler');

// const fs = require('fs');
// const DAI_ABI = JSON.parse(fs.readFileSync('./test/utils/Dai.abi', 'utf8'));

const MultiRewards = artifacts.require('MultiRewards');
const SliceToken = artifacts.require('SliceToken');
const RewardToken = artifacts.require('RewardToken');

const JFeesCollector = artifacts.require('JFeesCollector');
const JAdminTools = artifacts.require('JAdminTools');

const {ZERO_ADDRESS} = constants;

let jFCContract, jATContract;
let tokenOwner, user1, user2;

const fromWei = (x) => web3.utils.fromWei(x.toString());
const toWei = (x) => web3.utils.toWei(x.toString());
const fromWei8Dec = (x) => x / Math.pow(10, 8);
const toWei8Dec = (x) => x * Math.pow(10, 8);

contract("Multirewards", function (accounts) {

  it("ETH balances", async function () {
    tokenOwner = accounts[0];
    user1 = accounts[1];
    user2 = accounts[2];
    console.log(tokenOwner);
    console.log(await web3.eth.getBalance(tokenOwner));
    console.log(await web3.eth.getBalance(user1));
  });

  it("All other contracts ok", async function () {
    sliceContract = await SliceToken.deployed();
    expect(sliceContract.address).to.be.not.equal(ZERO_ADDRESS);
    expect(sliceContract.address).to.match(/0x[0-9a-fA-F]{40}/);
    console.log(sliceContract.address);

    rewardContract = await RewardToken.deployed();
    expect(rewardContract.address).to.be.not.equal(ZERO_ADDRESS);
    expect(rewardContract.address).to.match(/0x[0-9a-fA-F]{40}/);
    console.log(rewardContract.address);

    jFCContract = await JFeesCollector.deployed();
    expect(jFCContract.address).to.be.not.equal(ZERO_ADDRESS);
    expect(jFCContract.address).to.match(/0x[0-9a-fA-F]{40}/);
    console.log(jFCContract.address);

    jATContract = await JAdminTools.deployed();
    expect(jATContract.address).to.be.not.equal(ZERO_ADDRESS);
    expect(jATContract.address).to.match(/0x[0-9a-fA-F]{40}/);
    console.log(jATContract.address);

    mrContract = await MultiRewards.deployed();
    expect(mrContract.address).to.be.not.equal(ZERO_ADDRESS);
    expect(mrContract.address).to.match(/0x[0-9a-fA-F]{40}/);
    console.log(mrContract.address);
  });

  describe('sending rewards', function () {
    it('distribute rewards in slice and reward tokens', async function () {
      // reward token
      await rewardContract.approve(mrContract.address, toWei("100"), { from: tokenOwner });
      await mrContract.setRewardsDistributor(rewardContract.address, tokenOwner, { from: tokenOwner })
      await mrContract.setRewardsDuration(rewardContract.address, 1000, { from: tokenOwner })
      await mrContract.notifyRewardAmount(rewardContract.address, toWei("100"), { from: tokenOwner });
      res = await mrContract.rewardPerToken(rewardContract.address);
      console.log(res.toString())

      // slice token
      await sliceContract.approve(mrContract.address, toWei("10"), { from: tokenOwner });
      await mrContract.setRewardsDistributor(sliceContract.address, tokenOwner, { from: tokenOwner })
      await mrContract.setRewardsDuration(sliceContract.address, 1000, { from: tokenOwner })
      await mrContract.notifyRewardAmount(sliceContract.address, toWei("10"), { from: tokenOwner });
      res = await mrContract.rewardPerToken(sliceContract.address);
      console.log(res.toString())
    });

    it('staking slice', async function () {
      await sliceContract.approve(mrContract.address, toWei("1000"), { from: tokenOwner });
      await mrContract.stake(toWei(1000), { from: tokenOwner });
      res = await mrContract.rewardPerToken(rewardContract.address);
      console.log("reward tokens per slice: " + fromWei(res).toString())
      res = await mrContract.rewardPerToken(sliceContract.address);
      console.log("slice tokens per slice: " + fromWei(res).toString())
    });

    it('time passes...', async function () {
      const maturity = Number(time.duration.seconds(1100));
      let block = await web3.eth.getBlockNumber();
      console.log((await web3.eth.getBlock(block)).timestamp)

      await timeMachine.advanceTimeAndBlock(maturity);

      block = await web3.eth.getBlockNumber()
      console.log((await web3.eth.getBlock(block)).timestamp)
    });

    it('withdraw rewards', async function () {
      res = await mrContract.getReward({ from: tokenOwner });
      console.log("reward tokens balance: " + fromWei(await rewardContract.balanceOf(tokenOwner)).toString())
      console.log("slice tokens balance: " + fromWei(await sliceContract.balanceOf(tokenOwner)).toString())
    });

  });

  it('transfer values to JFC', async function () {
    // res = await mrContract.getReward({ from: tokenOwner });
    // console.log("reward tokens balance: " + fromWei(await rewardContract.balanceOf(tokenOwner)).toString())
    // console.log("slice tokens balance: " + fromWei(await sliceContract.balanceOf(tokenOwner)).toString())
  });

});