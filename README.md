This code is to create a proveably random smart contract lottery.

1. Users can enter by paying for a ticket
   1. The ticket fees are going to go to the winner during the draw
   2. After X period of time, the lottery will automatically draw a winner
      1. And this will be done programatically
      2. Using Chainlink VRF & Chainlink Automation
         1. Chainlink VRF -> Rnadomness
         2. Chainlink Automation -> Time Based Trigger

## Tests

1. Write some deploy script
2. Write our tests
   1. Work on local chain
   2. Forked Testnet
   3. Forked Mainnet
