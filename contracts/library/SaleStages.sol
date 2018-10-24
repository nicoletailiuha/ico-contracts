pragma solidity 0.4.24;

import "zeppelin-solidity/contracts/math/SafeMath.sol";

contract SaleStages {
    using SafeMath for uint256;

    enum Stage {
        SAFT,
        TGE,
        NONE
    }

    enum DiscountType {
      PRICE,
      DISCOUNT
    }

    struct Boundaries {
        uint256 low;
        uint256 high;
    }

    struct Usd {
      // USD denomination, e.g. priceUsd of 31250 at denomination 10 ** 6
      // means a real price of $0.031250
      uint256 denomination;
      uint256 amount;
    }

    struct Discount {
      DiscountType discountType; // Type of discount
      Boundaries usdInvestmentBoundaries; // Investment boundaries
      Usd priceUsd; // Discount price in USD
      uint256 discountPercentage; // Discount percentage in USD
    }

    struct StageInfo {
        Stage stage; // Stage to be applied on
        Boundaries tokensBoundaries; // Token boundaries to check
        Usd priceUsd; // Stage price in USD
        uint256 discountsLength;
        mapping (uint256 => Discount) discounts; // solidity doesn't support memory[] convertion to storage[]
    }

    StageInfo[] public saleStagesInfo; // Sale stages info
    uint256 public tokensSold; // tokens sold so far
    uint256 public ethToUsdRate = 200; // how many usd worth 1 ether ($200 = 1eth)

    /**
     * @dev push Discount into a StageInfo
     * @param _stageInfo stage info to be modifier
     * @param _discount discount to be added
     */
    function pushDiscount(StageInfo storage _stageInfo, Discount _discount) internal {
        _stageInfo.discounts[_stageInfo.discountsLength] = _discount;
        _stageInfo.discountsLength = _stageInfo.discountsLength.add(1);
    }

    /**
     * @dev retrieve how many tokens would be allocated for specified wei amount
     * @param _weiAmount number of wei-s to be converted to tokens
     */
    function getTokenAmount(
        uint256 _weiAmount
    )
        public
        view
        returns (uint256)
    {
        StageInfo storage _stageInfo = saleStageInfo();
        Usd memory _priceUsd = _stageInfo.priceUsd;
        uint256 _usdAmount = _weiAmount.mul(ethToUsdRate).div(10 ** 18);

        for (uint8 i = 0; i < _stageInfo.discountsLength; i++) {
            Discount storage _discount = _stageInfo.discounts[i];

            if (_usdAmount >= _discount.usdInvestmentBoundaries.low && _usdAmount < _discount.usdInvestmentBoundaries.high) {
                _priceUsd = _applyDiscount(_discount, _priceUsd);
                break;
            }
        }

        uint256 _tokenAmount = _weiAmount.mul(ethToUsdRate).mul(_priceUsd.denomination).div(_priceUsd.amount);

        return _tokenAmount;
    }

    /**
     * @dev retrieve current sale stage price
     */
    function saleStagePriceUsd() public view returns (uint256) {
        StageInfo storage _stageInfo = saleStageInfo();

        return _stageInfo.priceUsd.amount;
    }

    /**
     * @dev retrieve current sale stage
     */
    function saleStage() public view returns (Stage) {
        StageInfo storage _stageInfo = saleStageInfo();

        return _stageInfo.stage;
    }

    /**
     * @dev retrieve current sale stage information
     */
    function saleStageInfo()
        internal
        view
        returns (StageInfo storage)
    {
        for (uint8 i = 0; i < saleStagesInfo.length; i++) {
            StageInfo storage _stageInfo = saleStagesInfo[i];

            if (tokensSold >= _stageInfo.tokensBoundaries.low && tokensSold < _stageInfo.tokensBoundaries.high) {
                return _stageInfo;
            }
        }

        revert("UnknownSaleStageInfo");
    }

    /**
     * @dev retrieve the number of sale stages
     */
    function saleStagesLength() public view returns (uint256) {
        return saleStagesInfo.length;
    }

    /**
     * @dev applies Discount on a Usd object
     * @param _discount discount to be applied on a Usd object
     * @param _usd Usd to be discounted
     */
    function _applyDiscount(
        Discount _discount,
        Usd memory _usd
    )
        private
        pure
        returns (Usd)
    {
        if (_discount.discountType == DiscountType.PRICE) {
            return _discount.priceUsd;
        } else if (_discount.discountType == DiscountType.DISCOUNT) {
            Usd memory retUsd;

            retUsd.amount = _usd.amount.mul(100 - _discount.discountPercentage).div(100);
            retUsd.denomination = _usd.denomination;

            return retUsd;
        }

        revert("UnknownDiscountType");
    }
}
