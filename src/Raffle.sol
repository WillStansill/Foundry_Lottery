// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
@title A sample Raffle Contract
@author Will Stansill
@dev Implements Chainlink VRFv2
 */
contract Raffle is VRFConsumerBaseV2 {

    error Raffle_NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    enum RaffleState {
        OPEN,           //0
        CALCULATING     //1
    }

    // STATE VARIABLES

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint256 private s_lastTimeStamp;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    // EVENTS

    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
        i_gasLane = gasLane;
        s_raffleState = RaffleState.OPEN;

    }

    function enterRaffle() external payable{
       // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
        if(msg.value < i_entranceFee) {
            revert Raffle_NotEnoughEthSent();
        }
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }


    //When the winner is supposed to be picked
    function checkUpkeep(
        bytes memory /* checkData */

    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalace = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalace && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    
//      get a random number
//      user the number to pick a player
     function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gas lane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS, // number of block confirmations
            i_callbackGasLimit,
            NUM_WORDS
    );
        // Request the RNG
        // get the random number
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override{

        uint256 indexOfWinner = randomWords [0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;

    s_players = new address payable[](0);
    s_lastTimeStamp = block.timestamp;

        (bool success,) = winner.call{value: address(this).balance}("");
        if(!success) {
            revert Raffle__TransferFailed();
        }
        emit PickedWinner(winner);
    }
    

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState) {
        return s_raffleState;
    }
    function getPlayer(uint256 indexOfPlayer) external view returns(address) {
        return s_players[indexOfPlayer];
    }
}
