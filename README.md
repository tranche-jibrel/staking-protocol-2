# MultiRewards Staking Protocol

<img src="https://gblobscdn.gitbook.com/spaces%2F-MP969WsfbfQJJFgxp2K%2Favatar-1617981494187.png?alt=media" alt="Tranche Logo" width="100">

MultiRewards Protocol is a decentralized protocol for managing rewards to Slice stakers. More than 1 token could be distributed, each one with his own amount and duration

## Development

Current version deal with rewards distributed that resides outside the contract or outside of it, simply transferring tokens to this contract.

Fees Collector contract implements functions to call MultiRewards methods allowing to start new distribution with same parameters as the previous one.

Both ways to distribute rewards are now possible, electing the distributor contract in MultiRewards contract.

### Install Dependencies

```bash
npm i
```

### Compile project

```bash
truffle compile --all
```

### Run test

```bash
truffle run test
```

### Code Coverage

```bash
truffle run coverage
```

or to test a single file:

```bash
truffle run coverage --network development --file="<filename>"   
```

[(Back to top)](#MultiRewards-Staking-Protocol)

## Tranche Yearn Protocol Usage

Please refer to ./migrations/1_deploy_contracts.js file to see how the system could be deployed on the blockchain

Users can now call buy and redeem functions for tranche A & B tokens

Note: if ETH tranche is deployed, please deploy ETHGateway contract without a proxy, then set its address in JCompound with setETHGateway function.

[(Back to top)](#MultiRewards-Staking-Protocol)

## Tranche Migration to new Yearn version

You can migrate to a different Yearn version vault or token simply calling the following function:

```bash
migrateYTranche(uint256 _trancheNum, address _newYTokenAddress, bool _isVault)
```

All values will be sent to new vault and tokens inside contract will be switched with the new one, no other change

[(Back to top)](#MultiRewards-Staking-Protocol)

### Test Coverage

<table>
    <thead>
      <tr>
        <th>Name</th>
        <th>Test %</th>
        <th>Notes</th>
      </tr>
    </thead>
    <tbody>
        <tr>
            <td>JAdminTools</td>
            <td><code>100% &#x1F7E2;</code></td>
            <td>---</td>
        </tr>
        <tr>
            <td>JFeesCollector</td>
            <td><code>67.92% &#x1F7E1;</code></td>
            <td>---</td>
        </tr>
        <tr>
            <td>MultiRewards</td>
            <td><code>88.73% &#x1F7E2;</code></td>
            <td>---</td>
        </tr>
        <tr>
            <td>TransferETHHelper</td>
            <td><code>100% &#x1F7E2;</code></td>
            <td>---</td>
        </tr>
    </tbody>
  </table>

[(Back to top)](#MultiRewards-Staking-Protocol)

## Main contracts - Name, Size and Description

<table>
    <thead>
      <tr>
        <th>Name</th>
        <th>Size (KiB)</th>
        <th>Description</th>
      </tr>
    </thead>
    <tbody>
        <tr>
            <td>JAdminTools</td>
            <td><code>2.16</code></td>
            <td>Contract for administrative roles control (implementation), allowing the identification of addresses when dealing with reserved methods. Upgradeable.</td>
        </tr>
        <tr>
            <td>JAdminToolsStorage</td>
            <td><code>0.72</code></td>
            <td>Contract for administrative roles control (storage)</td>
        </tr>
        <tr>
            <td>JFeesCollector</td>
            <td><code>9.62</code></td>
            <td>Fees collector and uniswap swapper (implementation), it changes all fees and extra tokens into new interests for token holders, sending back extra mount to Compound protocol contract. Upgradeable.</td>
        </tr>
        <tr>
            <td>JFeesCollectorStorage</td>
            <td><code>0.82</code></td>
            <td>Fees collector and uniswap swapper (storage)</td>
        </tr>
        <tr>
            <td>MultiRewards</td>
            <td><code>7.48</code></td>
            <td>Multi Rewards contract (implementation), it distributes reward tokens to staker holder.</td>
        </tr>
        <tr>
            <td>MultiRewardsStorage</td>
            <td><code>0.69</code></td>
            <td>Multi Rewards contract (storage)</td>
        </tr>
        <tr>
            <td>TransferETHHelper</td>
            <td><code>0.08</code></td>
            <td>Utility contract to transfer ethers</td>
        </tr>
    </tbody>
  </table>

  [(Back to top)](#MultiRewards-Staking-Protocol)



