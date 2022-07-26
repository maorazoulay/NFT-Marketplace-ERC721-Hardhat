# Backend for ERC-721 NFT Marketplace

This project contains the smart contracts needed for a functioning ERC-721  based NFT Marketplace.

The project utillizes the Hardhat framework along with its useful plugins such as "hardhat-gas-reporter", "solidity-coverage", "hardhat-waffle" and "hardhat-etherscan".

The main contract, "Marketplace.sol" utiliizes best practices by using OpenZepplin's libraries wherever possible, such as ERC721.sol, IERC721Receiver.sol, ReentrancyGuard.sol and Counters.sol. 
The contract also comes with the appropriate unit tests which can be run by running 

```bash
npx hardhat test
```

## Installation

Install the node packages:

```bash
yarn install
```

Compile the Smart Contracts:
```bash
npx hardhat compile
```

## Deployment

to deploy the marketplace run the following command: 

```bash
npx run .\scripts\0-deploy-marketplace.js
```

Add the --network flag to choose your desired network. (runs on Hardhat local network by default)