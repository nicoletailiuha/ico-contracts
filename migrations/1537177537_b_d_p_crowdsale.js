const BDPCrowdsale = artifacts.require('BDPCrowdsale');

module.exports = async function(deployer) {
  const {
    WALLET_ADDRESS, INITIAL_RATE,
    ECOSYSTEM_ADDRESS, RESERVE_ADDRESS,
    TEAM_ADDRESS, ADVISORS_ADDRESSES, ADMIN_ADDRESSES
  } = process.env;

  await deployer.deploy(
    BDPCrowdsale,
    WALLET_ADDRESS, // wallet
    INITIAL_RATE, // rate
    ADMIN_ADDRESSES.split(',') // adminAddresses
  );

  const crowdsale = await BDPCrowdsale.deployed();

  await crowdsale.distributeInitialTokens(
    ECOSYSTEM_ADDRESS, // ecosystemAddress
    RESERVE_ADDRESS, // reserveAddress
    TEAM_ADDRESS, // teamAddress
    ADVISORS_ADDRESSES.split(','), // advisorsAddresses
  );
};
