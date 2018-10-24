const BDPCrowdsale = artifacts.require('BDPCrowdsale');

module.exports = async function(deployer) {
  const {
    WALLET_ADDRESS, ETH_TO_USD_RATE,
    ECOSYSTEM_ADDRESS, RESERVE_ADDRESS,
    TEAM_ADDRESS, ADVISORS_ADDRESSES, ADMIN_ADDRESSES
  } = process.env;

  await deployer.deploy(
    BDPCrowdsale,
    WALLET_ADDRESS, // wallet
    ETH_TO_USD_RATE, // rate
  );

  const crowdsale = await BDPCrowdsale.deployed();

  await crowdsale.addAddressesToAdmins(ADMIN_ADDRESSES.split(','));

  await crowdsale.distributeInitialTokens(
    ECOSYSTEM_ADDRESS, // ecosystemAddress
    RESERVE_ADDRESS, // reserveAddress
    TEAM_ADDRESS, // teamAddress
    ADVISORS_ADDRESSES.split(','), // advisorsAddresses
  );

  await crowdsale.initializeSaleStages();
};
