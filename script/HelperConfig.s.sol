// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { VRFCoordinatorV2Mock } from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import { LinkToken } from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee; 
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
    }

    // set the variable that holds configuration for the 
    // active network
    NetworkConfig public activeNetworkConfig;

    constructor(){
        if(block.chainid == 11155111){
            activeNetworkConfig = getSepoliaEthConfig();
        } else{
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            entranceFee: 0.1 ether, 
            interval: 30,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,//from Chainlink
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // the key hash from Chainlink
            subscriptionId: 10914,
            callbackGasLimit: 500_000, // 500,000 gas!
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory){
        // we should only create the activeNetworkConfig once
        if(activeNetworkConfig.vrfCoordinator != address(0)){
            return activeNetworkConfig;
        }

        uint96 baseFee = 0.25 ether; // i.e. 0.25 LINK
        uint96 gasPriceLink = 1e9;
        LinkToken link = new LinkToken();

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
            baseFee, gasPriceLink
        );
        vm.stopBroadcast();

        return NetworkConfig({
            entranceFee: 0.1 ether, 
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),//from the mock
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // the key hash from Chainlink
            subscriptionId: 10914,
            callbackGasLimit: 500_000, // 500,000 gas!
            link: address(link)
        });
    }
}