// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { DeployRaffle } from "../../script/DeployRaffle.s.sol";
import { Raffle } from "../../src/Raffle.sol";
import { Test, console } from "forge-std/Test.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { Vm } from "forge-std/Vm.sol";
import { VRFCoordinatorV2Mock } from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test{
    /** Events */
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee; 
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 constant public STARTING_USER_BALANCE = 10 ether;
    
    function setUp() external{
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee, 
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link,
            
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view{
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    ////////////////////////
    ///  enterRaffle    ///
    //////////////////////
    function testRaffleWhenYouDontPayEnough() public{
        // Arrange
        vm.prank(PLAYER);
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        assert(raffle.getPlayer(0) == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    modifier raffleEntered(){
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        _;
    }
    
    modifier timePassed(){
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork(){
        if(block.chainid != 31337){
            return;
        }
        _;
    }

    function testCantEnterWhenRaffleIsCalculating() public raffleEntered timePassed{
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    ////////////////////////
    ///  checkUpkeep    ///
    //////////////////////
    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public timePassed {
        
        (bool upkeepNeeded, ) = raffle.CheckUpkeep(" ");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public raffleEntered timePassed{
        
        raffle.performUpkeep(" ");

        (bool upkeepNeeded, ) = raffle.CheckUpkeep(" ");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasNotPassed() public raffleEntered {
        
        (bool upkeepNeeded, ) = raffle.CheckUpkeep(" ");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public raffleEntered timePassed {
        
        (bool upkeepNeeded, ) = raffle.CheckUpkeep(" ");
        assert(upkeepNeeded);
    }

    ////////////////////////
    ///  performUpkeep    ///
    //////////////////////
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public raffleEntered timePassed {
        
        raffle.performUpkeep(" ");

    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public skipFork {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                rState
            )
        );
        raffle.performUpkeep(" ");

    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() 
        public raffleEntered timePassed {
        vm.recordLogs(); // saves all output logs
        raffle.performUpkeep(" "); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[0].topics[1];

        Raffle.RaffleState rState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }

    ////////////////////////
    ///fulfilRandomWords ///
    //////////////////////
    function testFulfilRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) 
    public raffleEntered timePassed skipFork {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId, 
            address(raffle)
        );
    }
    
    function testFulfilRandomWordsPicksAWinnerResetsAndSendsMoney() 
        public raffleEntered timePassed skipFork {
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;
        for(uint256 i = startingIndex; 
            i < additionalEntrants + startingIndex;
            i++
        ){
            address player = address(uint160(i));
            hoax(player, STARTING_USER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 prize = entranceFee * (additionalEntrants + 1);

        vm.recordLogs(); // saves all output logs
        raffle.performUpkeep(" "); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[0].topics[2];

        uint256 previousTimeStamp = raffle.getLastTimeStamp();

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId), 
            address(raffle)
        );


        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getLengthOfPlayers() == 0);
        assert(previousTimeStamp < raffle.getLastTimeStamp());
        assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE + prize - entranceFee);
    }
    
}