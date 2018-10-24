pragma solidity 0.4.24;

import "./library/SaleStages.sol";


contract BDPSaleStages is SaleStages {
    /**
     * @dev Initialize TGE Stages
     */
    function initializeTgeStages() internal {
        _initializeTgeStage(
            150000000 * 10 ** 18,
            375000000 * 10 ** 18,
            Usd(10 ** 6, 32500)
        );

        _initializeTgeStage(
            375000000 * 10 ** 18,
            468750000 * 10 ** 18,
            Usd(10 ** 6, 40000)
        );

        _initializeTgeStage(
            468750000 * 10 ** 18,
            515625000 * 10 ** 18,
            Usd(10 ** 6, 45000)
        );

        _initializeTgeStage(
            515625000 * 10 ** 18,
            525000000 * 10 ** 18,
            Usd(10 ** 6, 47500)
        );
    }

    /**
     * @dev Initialize SAFT Stage
     */
    function initializeSaftStage() internal {
        StageInfo memory saftStage;
        Boundaries memory saftBoundaries;
        Boundaries memory saftDiscount100kBoundaries;
        Boundaries memory saftDiscount500kBoundaries;
        Usd memory saftPriceUsd;
        Usd memory saftDiscount100kPriceUsd;
        Usd memory saftDiscount500kPriceUsd;
        Discount memory saftDiscount100k;
        Discount memory saftDiscount500k;

        /** SAFT stage */

        // SAFT 0...150000000 BDP tokens
        saftBoundaries.low = 0;
        saftBoundaries.high = 150000000 * 10 ** 18;

        // <$100k investment > $0.031250
        saftPriceUsd.denomination = 10 ** 6;
        saftPriceUsd.amount = 31250;

        // >=$100k...500k investment > $0.027500
        saftDiscount100kBoundaries.low = 100000;
        saftDiscount100kBoundaries.high = 500000;

        saftDiscount100kPriceUsd.denomination = 10 ** 6;
        saftDiscount100kPriceUsd.amount = 27500;

        saftDiscount100k.discountType = DiscountType.PRICE;
        saftDiscount100k.usdInvestmentBoundaries = saftDiscount100kBoundaries;
        saftDiscount100k.priceUsd = saftDiscount100kPriceUsd;

        // >=500k investment > $0.022500
        saftDiscount500kBoundaries.low = 500000;
        saftDiscount500kBoundaries.high = ~uint256(0); // Max uint256 value

        saftDiscount500kPriceUsd.denomination = 10 ** 6;
        saftDiscount500kPriceUsd.amount = 22500;

        saftDiscount500k.discountType = DiscountType.PRICE;
        saftDiscount500k.usdInvestmentBoundaries = saftDiscount500kBoundaries;
        saftDiscount500k.priceUsd = saftDiscount500kPriceUsd;

        // Configure SAFT stage
        saftStage.stage = Stage.SAFT;
        saftStage.tokensBoundaries = saftBoundaries;
        saftStage.priceUsd = saftPriceUsd;

        saleStagesInfo.push(saftStage);

        pushDiscount(saleStagesInfo[0], saftDiscount100k);
        pushDiscount(saleStagesInfo[0], saftDiscount500k);
    }

    /**
     * @dev Initialize a single TGE Stage
     * @param _boundaryLow low boundary of the stage
     * @param _boundaryHigh high boundary of the stage
     * @param _usd USD Price
     */
    function _initializeTgeStage(
        uint256 _boundaryLow,
        uint256 _boundaryHigh,
        Usd _usd
    )
        private
    {
        StageInfo memory tgeStage;
        Boundaries memory tgeBoundaries;

        tgeBoundaries.low = _boundaryLow;
        tgeBoundaries.high = _boundaryHigh;

        // Configure TGE stage
        tgeStage.stage = Stage.TGE;
        tgeStage.tokensBoundaries = tgeBoundaries;
        tgeStage.priceUsd = _usd;

        Discount memory tgeDiscount1;
        Discount memory tgeDiscount2;
        Discount memory tgeDiscount3;
        Discount memory tgeDiscount4;

        tgeDiscount1.discountType = DiscountType.DISCOUNT;
        tgeDiscount1.usdInvestmentBoundaries.low = 50000;
        tgeDiscount1.usdInvestmentBoundaries.high = 100000;
        tgeDiscount1.discountPercentage = 5;

        tgeDiscount2.discountType = DiscountType.DISCOUNT;
        tgeDiscount2.usdInvestmentBoundaries.low = 50000;
        tgeDiscount2.usdInvestmentBoundaries.high = 100000;
        tgeDiscount2.discountPercentage = 10;

        tgeDiscount3.discountType = DiscountType.DISCOUNT;
        tgeDiscount3.usdInvestmentBoundaries.low = 100000;
        tgeDiscount3.usdInvestmentBoundaries.high = 500000;
        tgeDiscount3.discountPercentage = 15;

        tgeDiscount4.discountType = DiscountType.DISCOUNT;
        tgeDiscount4.usdInvestmentBoundaries.low = 500000;
        tgeDiscount4.usdInvestmentBoundaries.high = ~uint256(0);
        tgeDiscount4.discountPercentage = 20;

        // add TGE stage
        saleStagesInfo.push(tgeStage);

        uint256 idx = saleStagesInfo.length - 1;

        // pushDiscount works only on storage variables
        pushDiscount(saleStagesInfo[idx], tgeDiscount1);
        pushDiscount(saleStagesInfo[idx], tgeDiscount2);
        pushDiscount(saleStagesInfo[idx], tgeDiscount3);
        pushDiscount(saleStagesInfo[idx], tgeDiscount4);
    }
}
