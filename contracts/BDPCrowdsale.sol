pragma solidity 0.4.24;

import "zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./BDPToken.sol";
import "./library/LockStrategies.sol";
import "./library/Authorize.sol";
import "./BDPSaleStages.sol";


contract BDPCrowdsale is Authorize, BDPSaleStages {
    using SafeMath for uint256;
    using SafeERC20 for BDPToken;
    using LockStrategies for LockStrategies.LockedBalance;

    enum Stages {
        Investment,
        Finished
    }

    BDPToken public token;
    Stages public stage = Stages.Investment;

    uint256 public tokenCap = 1500000000 * 10 ** 18; // 1.5Bil
    uint256 public constant minEndTime = 1542283200; // 15 nov 2018
    uint256 public startedTime = now; // start immediately
    bool public initialDistribution = false;
    bool public stagesInitialized = false;
    uint256 public endedTime;
    uint256 public tokensAllocated;
    address public reserveAddress;
    address public wallet;

    mapping(address => LockStrategies.LockedBalance) public lockedBalanceOf;

    modifier atStage(Stages _stage) {
        require(stage == _stage, "WrongStage");
        _;
    }

    /**
     * @param _wallet Wallet address to forward funds to
     * @param _ethToUsdRate ETH<>Token Exchange rate
     */
    constructor(
        address _wallet,
        uint256 _ethToUsdRate // todo: remove
    ) public {
        wallet = _wallet;
        token = new BDPToken(address(this), tokenCap);

        setEthToUsdRate(_ethToUsdRate);

        // Asign admins and whitelisted managers for token burn mechanism
        addAuthorizeDependency(token);
    }

    function initializeSaleStages() public onlyIfAdminOrOwner(msg.sender) {
        require (!stagesInitialized, 'AlreadyInitialized');

        initializeSaftStage();
        initializeTgeStages();

        stagesInitialized = true;
    }

    /** ADMIN FUNCTIONALITY */

    /**
     * @dev Distribute initial amount of tokens
     * @param _ecosystemAddress Ecosystyem wallet address
     * @param _reserveAddress Reserve wallet address
     * @param _teamAddress Team wallet address
     * @param _advisorsAddresses Advisors wallet addresses
     */
    function distributeInitialTokens(
        address _ecosystemAddress,
        address _reserveAddress,
        address _teamAddress,
        address[] _advisorsAddresses
    )
        public
        onlyIfAdminOrOwner(msg.sender)
        atStage(Stages.Investment)
    {
        require(!initialDistribution, "AlreadyInitialized");

        reserveAddress = _reserveAddress;

        // Allocate 15% of tokens to ecosystem wallet
        _allocateTokens(_ecosystemAddress, tokenCap.mul(15).div(100), LockStrategies.LOCK_TYPE.UNLOCKED);

        // Allocate 30% of tokens to reserve wallet
        _allocateTokens(_reserveAddress, tokenCap.mul(30).div(100), LockStrategies.LOCK_TYPE.RESERVE);

        // Allocate 13% of tokens to team wallet
        _allocateTokens(_teamAddress, tokenCap.mul(13).div(100), LockStrategies.LOCK_TYPE.TEAM);

        // Allocate 7% of tokens divided in equal parts to advisors wallets
        uint256 advisorAmount = tokenCap.mul(7).div(100).div(_advisorsAddresses.length);

        for (uint256 i = 0; i < _advisorsAddresses.length; i++) {
            _allocateTokens(_advisorsAddresses[i], advisorAmount, LockStrategies.LOCK_TYPE.ADVISOR);
        }

        initialDistribution = true;
    }

    /**
     * @dev Finish crowdsale
     */
    function finish()
        public
        onlyIfAdminOrOwner(msg.sender)
        atStage(Stages.Investment)
    {
        require(now > minEndTime, "WrongTiming");

        // Allocate tokens which are unallocated to the reserve wallet
        _allocateTokens(reserveAddress, tokenCap.sub(tokensAllocated), LockStrategies.LOCK_TYPE.RESERVE);
        _finish();
    }

    /**
     * @dev Refund tokens owned by user. ETH refund will happen manually
     * @param _investorAddress Investors address to refund unreleased tokens
     */
    function refund(address _investorAddress)
        public
        onlyIfAdminOrOwner(msg.sender)
        atStage(Stages.Investment)
    {
        LockStrategies.LockedBalance storage investorBalance = lockedBalanceOf[_investorAddress];

        require(investorBalance.lockedAmount > 0, "NoRefundableTokens");

        tokensSold = tokensSold.sub(investorBalance.lockedAmount);
        tokensAllocated = tokensAllocated.sub(investorBalance.lockedAmount);

        investorBalance.refund();
    }

    /**
     * @dev Invest on behalf of an user
     * @param _beneficiary Tokens beneficiary address
     * @param _tokenAmount Amount of tokens
     * @param _referal Referal address to receive 5% of purchase
     */
    function investOnBehalfOf(
        address _beneficiary,
        uint256 _tokenAmount,
        address _referal
    )
        public
        atStage(Stages.Investment)
        onlyIfAdminOrOwner(msg.sender)
    {
        allocateTokens(
            _beneficiary,
            _tokenAmount,
            _referal,
            LockStrategies.LOCK_TYPE.INVESTOR
        );
    }

    /** INVESTOR FUNCTIONALITY */

    /**
     * @dev Buy tokens
     * @param _beneficiary Tokens beneficiary address
     * @param _referal Referal address to receive 5% of purchase
     */
    function buyTokens(
        address _beneficiary,
        address _referal
    )
        public
        payable
        onlyIfWhitelisted(msg.sender)
        atStage(Stages.Investment)
    {
        require(msg.value > 0, "NoValue");

        uint256 tokensBought = getTokenAmount(msg.value);

        allocateTokens(
            _beneficiary,
            tokensBought,
            _referal,
            LockStrategies.LOCK_TYPE.INVESTOR
        );

        // Forward funds to wallet
        wallet.transfer(msg.value);
    }

    /**
     * @dev Release tokens for a beneficiary
     * @param _beneficiary Tokens beneficiary
     */
    function releaseTokensFor(address _beneficiary) public {
        LockStrategies.LockedBalance storage beneficiaryBalance = lockedBalanceOf[_beneficiary];

        uint256 releasableAmount = beneficiaryBalance.getReleasableAmount(startedTime, endedTime);

        require(releasableAmount > 0, "NoReleasableTokens");

        beneficiaryBalance.release(releasableAmount);

        token.safeTransfer(_beneficiary, releasableAmount);
    }

    /**
     * @dev Get locked balance of a beneficiary
     * @param _beneficiary Tokens beneficiary address
     */
    function getLockedBalanceOf(address _beneficiary) public view returns (uint256) {
        return lockedBalanceOf[_beneficiary].lockedAmount;
    }

    /**
     * @dev Get relesable balance of a beneficiary
     * @param _beneficiary Tokens beneficiary address
     */
    function getReleasedBalanceOf(address _beneficiary) public view returns (uint256) {
        return lockedBalanceOf[_beneficiary].releasedAmount;
    }

    /**
     * @dev Fallback function for receiving ether sent to contract
     */
    function () public payable {
        buyTokens(msg.sender, address(0));
    }

    /** INTERNAL FUNCTIONS */

    /**
     * @dev Allocate tokens sold to beneficiary finish by cap if it's the case
     * @param _beneficiary Tokens beneficiary address
     * @param _amount Amount of tokens to allocate
     * @param _referal Referal address to receive 5% of purchase
     * @param _lockType Type of vesting period
     */
    function allocateTokens(
        address _beneficiary,
        uint256 _amount,
        address _referal,
        LockStrategies.LOCK_TYPE _lockType
    ) internal {
        require(initialDistribution, "NotInitialized");

        tokensSold = tokensSold.add(_amount);

        _allocateTokens(_beneficiary, _amount, _lockType);

        // Allocate 5% of tokens to the referal
        if (_referal != address(0)) {
            uint256 bonusAmount = _amount.mul(5).div(100);

            tokensSold = tokensSold.add(bonusAmount);

            _allocateTokens(
                _referal,
                bonusAmount,
                _lockType
            );
        }

        // If allocation reached the cap than finish crowsdale
        if (tokensAllocated >= tokenCap) {
            _finish();
        }
    }

    /**
     * @dev Finish crowdsale
     */
    function _finish() internal {
        stage = Stages.Finished;
        endedTime = now;
    }

    /**
     * @dev Allocate tokens to beneficiary
     * @param _beneficiary Tokens beneficiary address
     * @param _amount Amount of tokens to allocate
     * @param _lockType Type of vesting period
     */
    function _allocateTokens(
        address _beneficiary,
        uint256 _amount,
        LockStrategies.LOCK_TYPE _lockType
    ) internal {
        require(_beneficiary != address(0), "MissingBeneficiary");
        require(_amount > 0, "MissingAmount");
        require(tokensAllocated.add(_amount) <= tokenCap, "InsufficientTokens");

        tokensAllocated = tokensAllocated.add(_amount);
        lockedBalanceOf[_beneficiary].lockedAmount = lockedBalanceOf[_beneficiary].lockedAmount.add(_amount);
        lockedBalanceOf[_beneficiary].lockType = _lockType;
    }

    /**
     * @dev set eth to usd rate
     * @param _ethToUsdRate eth to usd rate to be setted
     */
    function setEthToUsdRate(uint256 _ethToUsdRate) public onlyIfAdminOrOwner(msg.sender) {
        ethToUsdRate = _ethToUsdRate;
    }
}
