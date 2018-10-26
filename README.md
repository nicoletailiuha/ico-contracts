# <img src="https://bidipass.org/img/logo.png">

The ICO contracts for [BidiPass](https://bidipass.org/).

# About the project

BidiPass is an identity authentication protocol
designed to strengthen today’s KYC model that global
businesses depend on.

By leveraging the blockchain and its own proprietary, BidiKey transfer protocol shores up the security
holes in existing KYC systems.

BidiPass doesn’t replace KYC as a service, but acts as a platform for accurate authentication of a user’s identity during a standard KYC check.

# BDP Token

The BDP token is:

- An ERC20 standard Ethereum blockchain-based token. BidiPass is based in a secure and trusted software technology.
- The token that keeps all BidiPass transactions running, and which acts as the sole form of payment within the BidiPass Network.
- Extremely straightforward to use. BDP Token is integrated into BidiPass transactions with no extra delays hassle for the user or service provider.
- A form of reward for using the BidiPass Network. Part of all BDP Token fees will be distributed directly to the user whenever they make a transaction using the BidiPass Network. These tokens can then be exchanged for security-related products provided by BidiPass and other Network service providers.


# BDP Crowdsale 

The BDP Crowdasle will have 2 main stages.
The SAFT stage (**150,000,000**) and the TGE stage (**375,000,000**).

Each stage will have a different token price based on the amount of tokens sold.
There are additional discounts on top of the base price, which is determined based on the volume of the investment committed.

Below you can find the token base price for each stage and the discounts:

<img src="/stages.png">

# Graph

<img src="/graph-diagram.png">

# Setup

Run the following commands to setup the project.

```sh
$ git clone https://github.com/BidiPassCompany/ico-contracts.git
$ cd ico-contracts
$ npm install
```

# Tests

First you must run testrpc with our seed on your machine. You can do this by running `bash ./bin/ganache.sh`

Then you can simply run `truffle test` to execute all tests
