pragma solidity 0.4.24;

import "./library/SaleStages.sol";


contract BDPSaleStages is SaleStages {
    function initializeSaleStages() internal {
        StageInfo saftStage;
        Boundaries saftBoundaries;
        Boundaries saftDiscount100kBoundaries;
        Boundaries saftDiscount500kBoundaries;
        Usd saftPriceUsd;
        Usd saftDiscount100kPriceUsd;
        Usd saftDiscount500kPriceUsd;
        Discount saftDiscount100k;
        Discount saftDiscount500k;

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
        saftStage.discounts.push(saftDiscount100k);
        saftStage.discounts.push(saftDiscount500k);

        // add SAFT stage
        saleStagesInfo.push(saftStage);

        /** TGE stage */
        
        StageInfo tgeStage1;
        Boundaries tgeBoundaries1;
        Usd tgePriceUsd1;

        // TGE 150000000...150000000+225000000 BDP tokens
        tgeBoundaries1.low = 150000000 * 10 ** 18;
        tgeBoundaries1.high = (150000000 + 225000000) * 10 ** 18;

        // $0.032500 for 225,000,000 BDP tokens
        tgePriceUsd1.denomination = 10 ** 6;
        tgePriceUsd1.amount = 32500;

        // Configure TGE stage
        tgeStage1.stage = Stage.TGE;
        tgeStage1.tokensBoundaries = tgeBoundaries1;
        tgeStage1.priceUsd = tgePriceUsd1;

        // add TGE stage
        saleStagesInfo.push(tgeStage1);
    }
}
