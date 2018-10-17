#!/usr/bin/env bash

ganache-cli \
  --accounts 50 \
  --defaultBalanceEther 1000000000000000 \
  --mnemonic "unlock post illegal spice fault album cable salad seminar razor crew believe" \
  --deterministic \
  --gasLimit 8000000 # same as mainnet & ropsten
