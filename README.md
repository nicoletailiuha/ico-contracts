Bidipass Contracts
==================

Bidipass ICO contracts

# TODO

- [x] Role based whitelisting

- [x] Re the other open point “Advisors & Service Providers - 7% of tokens”, as the crowdsale might go for longer than expected, the locking periods for this 7% allocation should start counting from when we deploy the smart contract and not from the end of the crowdsale. 

- [ ] Sale stages

- [ ] Rate logic (TGE phases)
The rate of token to USD is to determined based on the amount of investment (in the
SAFT phase) or the amount of tokens already bought (the TGE phase) according to the whitepaper. So in the SAFT phase (until 10% of the tokens are sold) investments of $500k have the token price of $0.022500, investments of $100k have the token price of $0.027500 and invesments of under $100k have the token price of $0.031250. In the TGE phases, the price changes based on the amount of tokens sold (information to be provided to us) and for the first phase it’s $0.032500, for the second - $0.040000, for the third - $0.045000 and for the fourth (the last one) - $0.047500. 

ethToUsdRate
usdToTokenRate
salePhase (SAFT 10% [150,000,000], TGE 25% [375,000,000])

SAFT price (150,000,000):
  >=500k = $0.022500
  >=$100k = $0.027500
  <$100k = $0.031250
TGE cliffs:
  i = $0.032500 for 225,000,000
  ii = $0.040000 for 93,750,000
  iii = $0.045000 for 46,875,000
  iv = $0.047500 for 9,375,000
TGE discounts:
  <50k = 0
  >=50k = 5%
  >=100k = 10%
  >=500k = 15%
  >=1000k = 20% 


- [ ] Airdrop (TBD)

- [ ] Re the individual allocations for each Advisor & Service Provider, they should be preallocated to each recipient from the moment we deploy the smart contract. We can provide the full list of recipients we have with their respective amounts and wallet addresses where they will receive the tokens.

# TODO Tests

- [ ] Airdrop
- [ ] TGE phases logic 
- [ ] Sale stages
