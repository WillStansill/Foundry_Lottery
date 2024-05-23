// SPDX-License-Identifier: MIT 

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";
import {console2} from "forge-std/Script.sol";

pragma solidity ^0.8.20;

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 newSubscriptionId,
            uint32 callbackGasLimit,
            address link
        ) = helperConfig.activeNetworkConfig();

        if(newSubscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            newSubscriptionId = createSubscription.createSubscription(vrfCoordinator);
            console2.log(newSubscriptionId);

            //Fund It!
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinator, newSubscriptionId, link);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            newSubscriptionId,
            callbackGasLimit
        );

        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), vrfCoordinator, newSubscriptionId);
        return (raffle, helperConfig);
    }
}