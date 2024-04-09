// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/// @title A Sample Raffle Contract
/// @author Nengak Emmanuel Goltong
/// @notice This Contract is for creating a sample raffle
/// @dev Implements Chainlink VRFv2

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
// import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

contract Raffle is VRFConsumerBaseV2 {
    /** Custom Errors */
    // prefixing errors with Contract names makes debugging easier
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
                uint256 currentBalance,
                uint256 numPlayers,
                uint256 raffleState
            );

    /** Types Declaration */
    enum RaffleState{
        OPEN,       // converted to 0
        CALCULATING // converted to 1
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    // setting the entranceFee for the raffle draw
    // this will be set at deployment which makes it immutable
    uint256 private immutable i_entranceFee;
    // @dev duration of the lottery in seconds
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint256 private s_lastTimeStamp;
    address payable[] private s_players; //addresses are marked payable so that winner can be paid
    address private s_recentWinner;
    RaffleState private s_raffleState;
    /** Events */
    event EnteredRafle(address indexed player);
    event PickedWinner(address indexed winner);

    /** Modifiers */
    modifier enoughFunds(){
        if(msg.value < i_entranceFee){
            revert Raffle__NotEnoughEthSent();
        }
        _;
    }

    modifier raffleIsOpen() {
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }
        _;
    }

    constructor(
        uint256 entranceFee, 
        uint256 interval, 
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        RaffleState raffleState
    ) VRFConsumerBaseV2(vrfCoordinator){
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = raffleState;
    }

    // CEI: Checks, Effects, Interactions
    function enterRaffle() external payable raffleIsOpen enoughFunds {
        // Checks (done by the modifiers 'raffleIsOpen' and 'enoughFunds')

        // Effects (on our Contract)

        // add message sender to array of players
        s_players.push(payable(msg.sender));
        // emit the event
        emit EnteredRafle(msg.sender);

        // Interactions (With other Contracts -> None)
    }

    // 1. Get a random number
    // 2. Use the random number to pick the winner
    // 3. Be automatically called

    // Chainlink Automation

    // When is the winner supposed to be picked?
    /**
    * @dev This is the function that the Chainlink Automation nodes call
    * to see if it's time to perform an upkeep.
    * The following should be true for this to return true:
    * 1. the time interval has passed between raffle runs
    * 2. the raffle is in the OPEN state
    * 3. the contract has ETH (aka, players)
    * 4. (Implicit) the subscription is funded with LINK
     */
    function CheckUpkeep(
        bytes memory /* checkData */
    ) public view returns(
        bool upkeepNeeded, bytes memory /* performData */
    ){
        bool timeHasPassed =  (block.timestamp - s_lastTimeStamp) >= i_interval; // checks if enough time has passed
        bool isOpen = s_raffleState == RaffleState.OPEN; // checks if raffle is open
        bool hasBalance = address(this).balance > 0; // Contract has ETH
        bool hasPlayers = s_players.length > 0; // Contract has players
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }   

    function performUpkeep(
        bytes calldata /* performData */
    ) external {
        // Checks
        (bool upkeepNeeded, ) = CheckUpkeep(" ");
        if(!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        
        // Effects (on our Contract)

        // close the raffle so that players cannot enter 
        // the raffle while a winner is being picked
        s_raffleState = RaffleState.CALCULATING;
        // 1. Request RNG from VRF
        // 2. Receive the random number generated

        // Interactions (with other Contracts)
        i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        // Checks

        // Effects (on our Contract)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN; // open the raffle since winner is already picked
        s_players = new address payable[](0); // reset the array of players
        s_lastTimeStamp = block.timestamp; // reset the timer for the next lottery
        emit PickedWinner(winner);

        // Interactions (With other Contracts)

        // pay the winner
        (bool success, ) = s_recentWinner.call{value: address(this).balance}("");
        if(!success){
            revert Raffle__TransferFailed();
        }
    }

    /** Getter Functions */
    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;
    }
}