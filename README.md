# Proveably Random Raffle Contracts

## About
This project is about creating a proveably random smart contract lottery

## What we want it to do
1. Users can enter by paying for a ticket
    1. The ticket fees are going to go to the winner during the draw

2. After X period of time, the lottery will automatically draw a winner
    1. And this will be done programmatically

3. Using Chainlink VRF and Chainlink Automation
    1. Chainlink VRF -> Randomness
    2. Chainlink Automation -> Time based trigger


## Importing the VRFv2 from Chainlink

```
forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit
```