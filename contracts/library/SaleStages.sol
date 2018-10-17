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
        Stages stage; // Stage to be applied on
        Boundaries tokensBoundaries; // Token boundaries to check
        Usd priceUsd; // Stage price in USD
        Discount[] discounts; // Discounts that might be applied
    }

    StageInfo[] public saleStagesInfo; // Sale stages info
    uint256 public tokensSold; // tokens sold so far
    uint256 public ethToUsdRate = 200; // how many usd worth 1 ether ($200 = 1eth)

    /**
     * @dev Get current stage of the crowdsale
     */
    function saleStage()
        internal
        pure
        returns (Stage)
    {
        if (tokensSold <= 150000000) {

            // SAFT stage of 10% from the cap (150,000,000)
            return Stage.SAFT;
        } else if (tokensSold <= 225000000) {
          
            // TGE  stage of 25% from the cap (225,000,000)
            return Stage.TGE;
        }

        return Stage.NONE;
    }

    /** 
     * @dev Get current rate in ETH (wei)
     * @param _investment Amount of investment in wei
     */
    function tokenEthRate(uint267 _investment)
        internal
        pure
        returns (uint256)
    {
        
    }

    /**
     * @dev Get current rate in USD
     * @param _investment Amount of investment in wei
     */
    function tokenUsdPrice(uint267 _investment)
        internal
        pure
        returns (uint256)
    {

    }
}
