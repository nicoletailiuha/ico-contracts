const Web3 = require('web3');

class EVMHelper {
  constructor(web3) {
    this.web3 = web3;
    this.lastTraveledTo = EVMHelper.now();
    this.logger = console.info;
  }

  static now() {
    return Math.ceil(Date.now() / 1000);
  }

  _formatLog(header, msg = null) {
    return `    > ${ msg ? `${ header }: ${ msg }` : header }`;
  }

  timeTravelTo(time, mine = true) {
    const travelDiff = parseInt(time) - this.lastTraveledTo;

    if (travelDiff < 0) {
      return Promise.reject(new Error('Unable to travel back in time.'));
    } else if (travelDiff === 0) {
      return Promise.resolve();
    }

    return this.timeTravel(travelDiff, mine);
  }

  timeTravel(time, mine = true) {
    return new Promise((resolve, reject) => {
      this.lastTraveledTo += time;

      this.logger(this._formatLog('Travel in time', new Date(this.lastTraveledTo * 1000).toISOString()));

      this.web3.currentProvider.sendAsync({
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [ time ],
        id: EVMHelper.now(),
      }, (error, result) => {
        if (error) {
          return reject(error);
        }

        resolve();
      });
    });
  }

  snapshot() {
    return new Promise((resolve, reject) => {
      this.logger(this._formatLog('Take snapshot'));

      this.web3.currentProvider.sendAsync({
        jsonrpc: '2.0',
        method: 'evm_snapshot',
        id: EVMHelper.now(),
      }, (error, result) => {
        if (error) {
          return reject(error);
        }

        resolve(result.result);
      });
    });
  }

  revert(snapshot, mine = true) {
    return new Promise((resolve, reject) => {
      this.logger(this._formatLog('Revert to state', snapshot));

      this.web3.currentProvider.sendAsync({
        jsonrpc: '2.0',
        method: 'evm_revert',
        params: [ snapshot ],
        id: EVMHelper.now(),
      }, (error, result) => {
        if (error) {
          return reject(error);
        }

        resolve();
      });
    });
  }
}


module.exports = {
  evm: web3 => new EVMHelper(web3),
};
