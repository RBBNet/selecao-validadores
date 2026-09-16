require("@nomicfoundation/hardhat-ethers");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.34",
    settings: {
      evmVersion: "berlin"
    }
  },
  paths: {
    sources: "./test/mocks",
    cache: "./cache_hh"
  }
};