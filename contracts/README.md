# curve-dao-contracts/contracts

All contract sources are within this directory.

## Subdirectories

- [`burners`](burners): Contracts used to convert admin fees into 3MOBI prior to distribution to the DAO.
- [`gauges`](gauges): Contracts used for measuring provided liquidity.
- [`testing`](testing): Contracts used exclusively for testing. Not considered to be a core part of this project.
- [`vests`](vests): Contracts for vesting MOBI.

## Contracts

- [`ERC20MOBI`](ERC20MOBI.vy): Mobius DAO Token (MOBI), an [ERC20](https://eips.ethereum.org/EIPS/eip-20) with piecewise-linear mining supply
- [`GaugeController`](GaugeController.vy): Controls liquidity gauges and the issuance of MOBI through the liquidity gauges
- [`LiquidityGauge`](LiquidityGauge.vy): Measures the amount of liquidity provided by each user
- [`LiquidityGaugeReward`](LiquidityGaugeReward.vy): Measures provided liquidity and stakes using [Synthetix rewards contract](https://github.com/Synthetixio/synthetix/blob/master/contracts/StakingRewards.sol)
- [`Minter`](Minter.vy): Token minting contract used for issuing new MOBI
- [`PoolProxy`](PoolProxy.vy): StableSwap pool proxy contract for interactions between the DAO and pool contracts
- [`VestingEscrow`](VestingEscrow.vy): Vests MOBI tokens for multiple addresses over multiple vesting periods
- [`VestingEscrowFactory`](VestingEscrowFactory.vy): Factory to store MOBI and deploy many simplified vesting contracts
- [`VestingEscrowSimple`](VestingEscrowSimple.vy): Simplified vesting contract that holds MOBI for a single address
- [`VotingEscrow`](VotingEscrow.vy): Vesting contract for locking MOBI to participate in DAO governance
