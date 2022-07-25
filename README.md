# Backend for ERC-721 NFT Marketplace

This project contains the smart contracts needed for a functioning ERC-721  based NFT Marketplace.

The project utillizes the Hardhat framework along with its useful plugins such as "hardhat-gas-reporter", "solidity-coverage", "hardhat-waffle" and "hardhat-etherscan".

The main contract, "Marketplace.sol" comes with unit tests which can be run by running "npx hardhat test". 

## Installation

Install the node packages:

```bash
yarn install
```

Compile the Smart Contracts:
```bash
npx hardhat compile
```