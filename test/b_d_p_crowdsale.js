require('dotenv').config();

const BigNumber = require('bignumber.js');
const { evm: createEvm } = require('./util');
const BDPCrowdsale = artifacts.require('BDPCrowdsale');
const BDPToken = artifacts.require('BDPToken');

contract('BDPCrowdsale', async function(accounts) {
  const evm = createEvm(web3);

  const {
    WALLET_ADDRESS, INITIAL_RATE,
    ECOSYSTEM_ADDRESS, RESERVE_ADDRESS,
    TEAM_ADDRESS, ADVISORS_ADDRESSES,
    ADMIN_ADDRESSES
  } = process.env;

  const ADMINS = ADMIN_ADDRESSES.split(',');
  const ADVISORS = ADVISORS_ADDRESSES.split(',');
  const randomAdmin = () => ADMINS[Math.floor(Math.random() * ADMINS.length)];

  const investorAddress = '0x070A36Ac98b0dDa8DE900bF86BBb8947a1c67fd9';
  const burnInvestorAddress = '0x85c7f192e57103435ce47147646922b762ce53fc';
  const referalAddress = '0x91edbe51edb03e24c8390469e97b10030df7b4b8';
  const refundAddress = '0xc6853e3317fbd8412cba712b86a664b5eac1f3f6';
  const refundTokens = new BigNumber(100).multipliedBy(10 ** 18);

  const burnAllowance = new BigNumber(6).multipliedBy(10 ** 18);
  let walletInitialBalance = 0;
  let ethInvestments = new BigNumber(0);
  let investorExpectedBalance = 0;
  const cap = new BigNumber(1.5 * 10 ** 9).multipliedBy(10 ** 18);
  const Stages = {
    Investment: 0,
    Finished: 1,
  };

  // @todo figure out why built in function not working
  async function getWalletBalance() {
    return new Promise((resolve, reject) => {
      web3.currentProvider.sendAsync({
        jsonrpc: '2.0',
        method: 'eth_getBalance',
        params: [ WALLET_ADDRESS ],
        id: Math.ceil(Date.now() / 1000),
      }, (error, result) => {
        if (error) {
          return reject(error);
        }

        resolve(new BigNumber(parseInt(result.result, 16)));
      });
    });
  }

  it('should initialize correctly', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();

    walletInitialBalance = await getWalletBalance();
    const ecosystemBalance = (await bdpCrowdsale.getLockedBalanceOf(ECOSYSTEM_ADDRESS)).toString(10);
    const reserveBalance = (await bdpCrowdsale.getLockedBalanceOf(RESERVE_ADDRESS)).toString(10);
    const teamBalance = (await bdpCrowdsale.getLockedBalanceOf(TEAM_ADDRESS)).toString(10);
    const tokensAllocated = (await bdpCrowdsale.tokensAllocated.call()).toString(10);

    let advisorsBalance = new BigNumber(0);

    for (const advisorAddress of ADVISORS) {
      advisorsBalance = advisorsBalance.plus(
        (await bdpCrowdsale.getLockedBalanceOf(advisorAddress)).toString(10)
      );
    }

    // Check if admins were added
    for (const adminAddress of ADMINS) {
      assert.isTrue(await bdpCrowdsale.admin(adminAddress));
    }

    assert.equal(WALLET_ADDRESS.toLowerCase(), await bdpCrowdsale.wallet.call()); // wallet address
    assert.equal('0', (await bdpCrowdsale.tokensSold.call()).toString(10)); // tokens sold
    assert.equal(new BigNumber(0.65).multipliedBy(cap).toString(10), tokensAllocated); // allocated token
    assert.equal(new BigNumber(0.15).multipliedBy(cap).toString(10), ecosystemBalance); // 15%
    assert.equal(new BigNumber(0.30).multipliedBy(cap).toString(10), reserveBalance); // 30%
    assert.equal(new BigNumber(0.13).multipliedBy(cap).toString(10), teamBalance); // 13%
    assert.equal(new BigNumber(0.07).multipliedBy(cap).toString(10), advisorsBalance.toString(10)); // 7%
  });

  it ('should allow token release for ecosystem address', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();
    const tokenAddress = await bdpCrowdsale.token.call();
    const tokenContract = await BDPToken.at(tokenAddress);

    await bdpCrowdsale.releaseTokensFor(ECOSYSTEM_ADDRESS);

    const ecosystemBalance = (await tokenContract.balanceOf(ECOSYSTEM_ADDRESS)).toString(10);

    assert.equal(new BigNumber(0.15).multipliedBy(cap).toString(10), ecosystemBalance); // 15%
  });

  it ('should deny token release for RESERVE_ADDRESS', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();

    let error = null;

    try {
      await bdpCrowdsale.releaseTokensFor(RESERVE_ADDRESS);
    } catch (e) {
      error = e;
    }

    assert.isNotNull(error);
  });

  it ('should deny token release for TEAM_ADDRESS', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();

    let error = null;

    try {
      await bdpCrowdsale.releaseTokensFor(TEAM_ADDRESS);
    } catch (e) {
      error = e;
    }

    assert.isNotNull(error);
  });

  it ('should deny token release for one of advisors', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();

    let error = null;

    try {
      await bdpCrowdsale.releaseTokensFor(ADVISORS[0]);
    } catch (e) {
      error = e;
    }

    assert.isNotNull(error);
  });

  Date.now() < 1542283200000 && it ('should deny crowdsale finish before 15 nov', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();

    let error = null;

    try {
      await bdpCrowdsale.finish();
    } catch (e) {
      error = e;
    }

    assert.isNotNull(error);
  });

  it ('should deny buyTokens for non whitelisted addresses', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();

    let error = null;

    try {
      await bdpCrowdsale.buyTokens(investorAddress, 0x0, {
        value: 10 ** 19,
        from: investorAddress
      });
    } catch (e) {
      error = e;
    }

    assert.isNotNull(error);
  });

  it ('should allow buyTokens for whitelisted addresses (incl. referal bonus)', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();
    const rate = (await bdpCrowdsale.rate()).toNumber();

    const investmentAmount = 10 ** 17;

    await bdpCrowdsale.addAddressToWhitelist(investorAddress);
    await bdpCrowdsale.buyTokens(investorAddress, referalAddress, {
      value: investmentAmount,
      from: investorAddress
    });

    const lockedInvestorBalance = await bdpCrowdsale.getLockedBalanceOf(investorAddress);
    const lockedReferalBalance = await bdpCrowdsale.getLockedBalanceOf(referalAddress);

    ethInvestments = ethInvestments.plus(investmentAmount);
    investorExpectedBalance += investmentAmount * rate;

    assert.equal(investorExpectedBalance, lockedInvestorBalance.toNumber());
    assert.equal(investmentAmount * rate * 5 / 100, lockedReferalBalance.toNumber());
  });

  it ('should increase balance of investor on investOnBehalf call', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();

    const tokenAmount = 10 ** 16;
    await bdpCrowdsale.addAddressToWhitelist(investorAddress);
    // try investing from random admin address
    await bdpCrowdsale.investOnBehalfOf(investorAddress, tokenAmount, 0x0, { from: randomAdmin() });

    const lockedInvestorBalance = await bdpCrowdsale.getLockedBalanceOf(investorAddress);

    investorExpectedBalance += tokenAmount;

    assert.equal(investorExpectedBalance, lockedInvestorBalance.toNumber());
  });

  it ('should allow refunding tokens', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();

    await bdpCrowdsale.investOnBehalfOf(refundAddress, refundTokens.toString(10), 0x0);

    const tokensSold = await bdpCrowdsale.tokensSold.call();
    const tokensAllocated = await bdpCrowdsale.tokensAllocated.call();

    assert.equal(
      refundTokens.toString(10),
      (await bdpCrowdsale.getLockedBalanceOf(refundAddress)).toString(10)
    );

    await bdpCrowdsale.refund(refundAddress);

    const tokensSoldAfter = await bdpCrowdsale.tokensSold.call();
    const tokensAllocatedAfter = await bdpCrowdsale.tokensAllocated.call();

    assert.equal(
      '0',
      (await bdpCrowdsale.getLockedBalanceOf(refundAddress)).toString(10)
    );
    assert.equal(tokensSold.sub(refundTokens.toString(10)).toString(10), tokensSoldAfter.toString(10));
    assert.equal(tokensAllocated.sub(refundTokens.toString(10)).toString(10), tokensAllocatedAfter.toString(10));
  });

  it ('should allow whitelisting token managers', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();
    const tokenAddress = await bdpCrowdsale.token.call();
    const tokenContract = await BDPToken.at(tokenAddress);

    const managerAddress = randomAdmin();
    const burnInvestmentEth = burnAllowance.dividedBy(INITIAL_RATE).toString(10);

    await bdpCrowdsale.addAddressToWhitelist(burnInvestorAddress);
    await bdpCrowdsale.buyTokens(burnInvestorAddress, 0x0, {
      value: burnInvestmentEth,
      from: burnInvestorAddress
    });
    await tokenContract.setBurnAllowance(burnInvestorAddress, burnAllowance.toString(10), {
      from: managerAddress
    });

    ethInvestments = ethInvestments.plus(burnInvestmentEth);

    assert.isTrue(await tokenContract.whitelist.call(managerAddress));
  });

  it ('should change stage to finished after cap reached', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();

    const snapshot = await evm.snapshot();
    const tokensAllocated = await bdpCrowdsale.tokensAllocated.call();
    const tokensLeft = tokensAllocated.sub(cap.toString(10)).abs();

    await bdpCrowdsale.addAddressToWhitelist(investorAddress);
    await bdpCrowdsale.investOnBehalfOf(investorAddress, tokensLeft.toString(10), 0x0);

    assert.equal(cap.toString(10), (await bdpCrowdsale.tokenCap.call()).toString(10));
    assert.equal(Stages.Finished, (await bdpCrowdsale.stage.call()).toNumber());

    await evm.revert(snapshot);
  });

  it ('should setup endedTime and change stage to finished on "finish" call', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();
    const preEndTime = Date.now() / 1000 + 5260000;

    const reserveTokensBefore = await bdpCrowdsale.getLockedBalanceOf.call(RESERVE_ADDRESS);
    const tokensAllocated = await bdpCrowdsale.tokensAllocated.call();
    const tokensUnsold = tokensAllocated.sub(cap).abs();

    await evm.timeTravel(7890000); // 3 months

    await bdpCrowdsale.finish();

    const reserveTokens = (await bdpCrowdsale.getLockedBalanceOf.call(RESERVE_ADDRESS)).toString(10);
    const stage = await bdpCrowdsale.stage();
    const endedTime = await bdpCrowdsale.endedTime();

    assert.equal(reserveTokensBefore.add(tokensUnsold).toString(10), reserveTokens);
    assert.equal(Stages.Finished, stage.toNumber());
    assert.isTrue(preEndTime < endedTime);
  });

  it ('should release first half of locked tokens for advisors after 3 months after contest deploy', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();
    const tokenAddress = await bdpCrowdsale.token.call();
    const tokenContract = await BDPToken.at(tokenAddress);

    for (const advisorAddress of ADVISORS) {
      await bdpCrowdsale.releaseTokensFor(advisorAddress);

      const advisorsBalance = (await tokenContract.balanceOf(advisorAddress)).toString(10);

      assert.equal(new BigNumber(0.035).multipliedBy(cap).dividedBy(ADVISORS.length).toString(10), advisorsBalance); // half of 7%
    }
  });

  it ('should not allow repeated release after 3 months for advisors', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();

    let error = null;

    try {
      await bdpCrowdsale.releaseTokensFor(ADVISORS[0]);
    } catch (e) {
      error = e;
    }

    assert.isNotNull(error);
  });

  it ('should release second half of locked tokens for advisors after 6 months after contest deployed', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();
    const tokenAddress = await bdpCrowdsale.token.call();
    const tokenContract = await BDPToken.at(tokenAddress);

    await evm.timeTravel(7890000); // 3 months, 3 months already passed in previous tests

    for (const advisorAddress of ADVISORS) {
      await bdpCrowdsale.releaseTokensFor(advisorAddress);

      const advisorsBalance = (await tokenContract.balanceOf(advisorAddress)).toString(10);

      assert.equal(new BigNumber(0.07).multipliedBy(cap).dividedBy(ADVISORS.length).toString(10), advisorsBalance); // half of 7%
    }
  });

  it ('should allow token release after 6 months for RESERVE_ADDRESS', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();
    const tokenAddress = await bdpCrowdsale.token.call();
    const tokenContract = await BDPToken.at(tokenAddress);

    await evm.timeTravel(15780000); // 6 months
    await bdpCrowdsale.releaseTokensFor(RESERVE_ADDRESS);

    const reserveBalance = (await tokenContract.balanceOf(RESERVE_ADDRESS)).toNumber();

    assert.equal((await bdpCrowdsale.getLockedBalanceOf(RESERVE_ADDRESS)).toNumber(), 0); // should not have locked tokens
    assert.isAtLeast(reserveBalance, new BigNumber(0.3).multipliedBy(cap).toNumber()); // 30% + unsold tokens if any
  });

  it ('should release all tokens for investors after 6 months have passed', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();
    const tokenAddress = await bdpCrowdsale.token.call();
    const tokenContract = await BDPToken.at(tokenAddress);

    await bdpCrowdsale.releaseTokensFor(investorAddress);

    const investorBalance = await tokenContract.balanceOf(investorAddress);

    assert.equal(investorExpectedBalance, investorBalance.toNumber());
  });

  it ('should burn allowed amount of tokens', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();
    const tokenAddress = await bdpCrowdsale.token.call();
    const tokenContract = await BDPToken.at(tokenAddress);

    let error = null;

    await bdpCrowdsale.releaseTokensFor(burnInvestorAddress);

    try {
      await tokenContract.burn(burnAllowance.toString(10), {
        from: burnInvestorAddress
      });
    } catch (e) {
      error = e;
    }

    assert.isNull(error);
  });

  it ('should not allow burning tokens without allowance', async () => {
    const bdpCrowdsale = await BDPCrowdsale.deployed();
    const tokenAddress = await bdpCrowdsale.token.call();
    const tokenContract = await BDPToken.at(tokenAddress);

    let error = null;

    try {
      await tokenContract.burn(burnAllowance.toString(10), {
        from: burnInvestorAddress
      });
    } catch (e) {
      error = e;
    }

    assert.isNotNull(error);
  });

  it ('should forward ETH to wallet', async () => {
    const walletFunds = await getWalletBalance();

    assert.equal(walletInitialBalance.plus(ethInvestments).toString(10), walletFunds.toString(10));
  });
});
