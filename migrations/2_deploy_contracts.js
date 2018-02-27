const ERC721 = artifacts.require("./ERC721.sol");

module.exports = function(deployer) {
    deployer.deploy(ERC721, "FooBarCoin", "FBC");
};