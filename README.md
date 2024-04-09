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

To import VRFv2 from Chainlink for use in our Contract, we use this command
```
forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit
```

Next, we go to our `foundry.toml` file and use `remappings` to redirect our imports to the location of the relevant file imports on our local machine. This is because sometimes, when we download dependencies on our local machine, the file path may vary from what the github repo is. We remap in `foundry.toml` using the following command
```
remappings = ["@chainlink/contracts/src/v0.8/vrf=lib/chainlink-brownie-contracts/contracts/src/v0.8"]
```
so that the entire `foundry.toml` file becomes
```
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = ["@chainlink/contracts/src/v0.8/vrf=lib/chainlink-brownie-contracts/contracts/src/v0.8"]
```