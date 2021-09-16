from brownie import (
    accounts, 
    VestingEscrow
)

from web3.gas_strategies.time_based import fast_gas_price_strategy as gas_strategy


def main():
    vesting = VestingEscrow.at("0xf062e30a44202b1c09fAf2e87B385ead3F42d231")
    print(vesting.vestedSupply())
    print(vesting.vestedOf("0x59A6AbC89C158ef88d5872CaB4aC3B08474883D9"))
