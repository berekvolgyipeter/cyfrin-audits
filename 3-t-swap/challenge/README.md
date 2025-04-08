# Challenge

Break the invariant of the [pool](https://vscode.blockscan.com/sepolia/0xdeb8d8efef7049e280af1d5fe3a380f3be93b648) of this [tripool stablecoin DEX](https://sepolia.etherscan.io/address/0xdeb8d8efef7049e280af1d5fe3a380f3be93b648#code).

## Invariant

We should always be able to get the same or more tokens out than we put in.
For example: 
  - One should be able to deposit 100 tokenA, 100 tokenB, and 100 tokenC for a total of 300 tokens 
  - On redemption, they should get at least 300 tokens back, never less

## Notes

- LP token is only minted at deposit
- in theory, during swaps, the sum balance of tokens should remain the same or increase, never decrease
  
### Withdraw example

  - total 200 LP tokens, we hold 100
  - total token balances of pool
    - 300 tokenA
    - 200 tokenB
    - 100 tokenC
  - we receive
    - 100 * 300 / 200 = 150 tokenA
    - 100 * 200 / 200 = 100 tokenB
    - 100 * 100 / 200 = 50 tokenC
    - a total of 300 tokens

### Swap

The `swapFrom` function doesn't take fee, just reduces the amount by 0.02%. So the comment of having a 0.03% fee is incorrect - both the fact and the amount.
However 0.01% is added to the `s_totalOwnerFees` state variable. Something is fishy arounf here.

### Collect fees

The `collectOwnerFees` function transfers `s_totalOwnerFees` amount of tokenA to the pool's owner.
According to description this function should transfer the amount in the selected token, but that's not the case.

## Invariant break

Since there is no fee collected, but the cumulated amount of 0.01 percentages of swaps can be transferred to the owner, that actually drains the tokens from the pool, which will have the effect that LPs can redeem less tokens that they deposited.

### Proof of Concept

- There are a total of 200 LP tokens, we hold 100
- The pool balances are:
  - 200 tokenA
  - 200 tokenB
  - 200 tokenC
- Someone swaps 100 tokenA for tokenB
- The pool token balances are then:
  - 299.98 tokenA
  - 100.02 tokenB
  - 200 tokenC
- owner fees are collected, and 0.01 tokenA is removed from the pool:
  - 299.97 tokenA
  - 100.02 tokenB
  - 200 tokenC
- now if we redeem, we get:
  - 100 * 299.97 / 200 = 149.985 tokenA
  - 100 * 100.02 / 200 = 50.01 tokenB
  - 100 200 / 200 = 100 tokenC
  - a total of 299.995 tokens which is less than our deposited 300 tokens!
