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

## Tests
1. We write some deploy scripts
```bash
touch ./script/DeployRaffle.s.sol
```
Because the constructor function of `Raffle` contract in our `Raffle.sol` takes input parameters some of which depend on the chain we wish to deploy the contract to, we create a `HelperConfig` file using the following command
```bash
touch ./script/HelperConfig.s.sol
```
The `HelperConfig` file is to make our deployment flexible and modular.

We create a mock VRF Coordinator for our Anvil chain by importing the mock script in the chainlink brownie contracts directory thus
```bash
import { VRFCoordinatorV2Mock } from "@chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
```


2. We write some tests
    1. Work on local chain
    2. Work on forked Testnet
    3. Work on forked Mainnet

### Unit Test
For our unit test, we create a `RaffleTest.t.sol` file using the command 
```bash
mkdir ./test/unit && touch ./test/unit/RaffleTest.t.sol
```

To run a test, use the following command 
```bash
forge test
```

To check the test coverage, use the following command
```bash
forge coverage
```


### Integration Test
For our integration test, we create a `IntegrationTest.t.sol` file inside the `integration` directory using the command 
```bash
mkdir ./test/integration && touch ./test/integration/IntegrationTest.t.sol
```
