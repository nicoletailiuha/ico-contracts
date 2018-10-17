pragma solidity 0.4.24;

import "zeppelin-solidity/contracts/math/SafeMath.sol";

library LockStrategies {
    using SafeMath for uint256;

    uint256 private constant THREE_MONTHS = 7890000;
    uint256 private constant SIX_MONTHS = 15780000;
    uint256 private constant ONE_YEAR = 31536000;
    uint256 private constant TWO_YEARS = 63072000;
    uint256 private constant THREE_YEARS = 94608000;
    uint256 private constant FOUR_YEARS = 126144000;

    enum LOCK_TYPE {
        UNLOCKED,
        RESERVE,
        TEAM,
        INVESTOR,
        ADVISOR
    }

    struct LockedBalance {
        LOCK_TYPE lockType;
        uint256 lockedAmount;
        uint256 releasedAmount;
    }

    /**
     * @dev Returns the releasable amount of tokens
     * @param _startedTime Crowdsale start time
     * @param _endedTime Crowdsale end time
     */
    function getReleasableAmount(
        LockedBalance _self,
        uint256 _startedTime,
        uint256 _endedTime
    )
        internal
        view
        returns (uint256)
    {
        require(_self.lockedAmount != 0, "NoLockedTokens");

        if (_self.lockType == LOCK_TYPE.INVESTOR) {
            return _investorReleasableAmount(_self, _endedTime);
        } else if (_self.lockType == LOCK_TYPE.UNLOCKED) {
            return _unlockedReleasableAmount(_self);
        } else if (_self.lockType == LOCK_TYPE.RESERVE) {
            return _reserveReleasableAmount(_self, _startedTime);
        } else if (_self.lockType == LOCK_TYPE.TEAM) {
            return _teamReleasableAmount(_self, _endedTime);
        }  else if (_self.lockType == LOCK_TYPE.ADVISOR) {
            return _advisorReleasableAmount(_self, _startedTime);
        }

        revert("UnknownLockType");
    }

    /**
     * @dev Get total amount of tokens available for an address
     */
    function getTotalAmount(LockedBalance _self)
        internal
        pure
        returns (uint256)
    {
        return _self.lockedAmount.add(_self.releasedAmount);
    }

    /**
     * @dev Release an amount of tokens
     * @param _amount Amount of tokens to releaase
     */
    function release(
        LockedBalance storage _self,
        uint256 _amount
    )
        internal
    {
        require(_amount <= _self.lockedAmount, "BadClaimAmount");

        _self.lockedAmount = _self.lockedAmount.sub(_amount);
        _self.releasedAmount = _self.releasedAmount.add(_amount);
    }

    /**
     * @dev Refund unreleased amount of tokens
     */
    function refund(LockedBalance storage _self) internal {
        _self.lockedAmount = 0;
    }

    /** INTERNAL FUNCTIONS */

    /**
     * @dev Get total unrelesed amount
     */
    function _unlockedReleasableAmount(LockedBalance _self)
        private
        pure
        returns (uint256)
    {
        return _self.lockedAmount;
    }

    /**
     * @dev Get releasable amount for reserve lock type
     * @param _startedTime Crowdsale start time
     */
    function _reserveReleasableAmount(
        LockedBalance _self,
        uint256 _startedTime
    )
        private
        view
        returns (uint256)
    {
        if (_self.releasedAmount != 0) {
            return 0;
        }

        uint256 timePassed = now.sub(_startedTime);

        if (timePassed >= SIX_MONTHS) {
            return _self.lockedAmount;
        }

        return 0;
    }

    /**
     * @dev Get releasable amount for advisors lock type
     * @param _startedTime Crowdsale start time
     */
    function _advisorReleasableAmount(
        LockedBalance _self,
        uint256 _startedTime
    )
        private
        view
        returns (uint256)
    {
        uint256 totalAmount = getTotalAmount(_self);
        uint256 releasableAmount;
        uint256 timePassed = now.sub(_startedTime);

        if (timePassed >= SIX_MONTHS) {
            releasableAmount = totalAmount; // 100%
        } else if (timePassed >= THREE_MONTHS) {
            releasableAmount = totalAmount.div(2); // 50%
        }

        if (releasableAmount <= _self.releasedAmount) {
            return 0;
        }

        return releasableAmount.sub(_self.releasedAmount);
    }

    /**
     * @dev Get releasable amount for investor lock type
     * @param _endedTime Crowdsale end time
     */
    function _investorReleasableAmount(
        LockedBalance _self,
        uint256 _endedTime
    )
        private
        view
        returns (uint256)
    {
        if (_endedTime == 0) {
            return 0;
        }

        uint256 totalAmount = getTotalAmount(_self);
        uint256 releasableAmount;
        uint256 timePassed = now.sub(_endedTime);

        if (timePassed >= SIX_MONTHS) {
            releasableAmount = totalAmount; // 100%
        } else if (timePassed >= THREE_MONTHS) {
            releasableAmount = totalAmount.div(2); // 50%
        }

        if (releasableAmount <= _self.releasedAmount) {
            return 0;
        }

        return releasableAmount.sub(_self.releasedAmount);
    }

    /**
     * @dev Get releasable amount for team lock type
     * @param _endedTime Crowdsale end time
     */
    function _teamReleasableAmount(
        LockedBalance _self,
        uint256 _endedTime
    )
        private
        view
        returns (uint256)
    {
        if (_endedTime == 0) {
            return 0;
        }

        uint256 totalAmount = getTotalAmount(_self);
        uint256 releasableAmount;
        uint256 timePassed = now.sub(_endedTime);

        if (timePassed >= FOUR_YEARS) {
            releasableAmount = totalAmount; // 100%
        } else if (timePassed >= THREE_YEARS) {
            releasableAmount = totalAmount.mul(3).div(4); // 75%
        } else if (timePassed >= TWO_YEARS) {
            releasableAmount = totalAmount.div(2); // 50%
        } else if (timePassed >= ONE_YEAR) {
            releasableAmount = totalAmount.div(4); // 25%
        }

        if (releasableAmount <= _self.releasedAmount) {
            return 0;
        }

        return releasableAmount.sub(_self.releasedAmount);
    }
}
