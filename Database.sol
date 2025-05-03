//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./TradeWallet.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./EnumerableSet.sol";

/**
    Tracks all projects currently running a volume bot
    Tracks all data associated
 */
contract Database is Ownable {

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    address public constant v3Router = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
    address public constant v2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    struct Config {
        uint256 frequency; // in seconds
        uint8 buysPerSell; // number of buys that happen before a sell
        uint16 percentPerTrade; // in basis points (10,000 = 100%)
    }

    struct Status {
        bool isActive; // is the bot active
        uint256 lastTradeTime; // last time a trade was executed
        uint256 remainingBNB; // remaining BNB in the contract
        uint256 totalTokenVolume; // total volume of tokens traded
        uint256 totalBNBVolume; // total volume of BNB traded
        uint8 consecutiveBuys; // current number of consecutive buys
        address[] wallets;  // all wallets which own tokens
        EnumerableSet.AddressSet activeWallets; // all wallets which actively have tokens to be sold
    }

    struct Project {
        address tokenAddress;
        address dexAddress;
        address pairAddress;
        uint256 initialBNB;
        Config config;
        Status status;
    }

    mapping ( uint256 => Project ) public projects; // projectId => Project

    mapping ( address => uint256[] ) public tokenProjects; // tokenAddress => projectIds

    mapping ( address => bool ) public canRunProject; // address => canRunProject

    uint256 public projectNonce = 1; // projectId

    uint256 public platformFee = 250;

    address public feeReceiver;

    uint256 public constant FEE_DENOMINATOR = 10_000; // 100% = 10,000 basis points

    uint256 public minAmountToTrade = 0.05 ether; // 0.05 BNB

    uint256 public minStartAmount = 1 ether; // 0.05 BNB

    address public tradeWalletMasterCopy;

    bool public isPublic;

    EnumerableSet.UintSet private activeProjects; // all active projects

    constructor(address _tradeWalletMasterCopy, address _feeReceiver) {
        tradeWalletMasterCopy = _tradeWalletMasterCopy;
        feeReceiver = _feeReceiver;
        isPublic = false; // private mode by default
    }

    function setMinStartAmount(uint256 _minStartAmount) external onlyOwner {
        minStartAmount = _minStartAmount;
    }

    function setMinAmountToTrade(uint256 _minAmountToTrade) external onlyOwner {
        minAmountToTrade = _minAmountToTrade;
    }

    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee < FEE_DENOMINATOR, "Platform fee too high");
        platformFee = _platformFee;
    }

    function setTradeWalletMasterCopy(address _tradeWalletMasterCopy) external onlyOwner {
        tradeWalletMasterCopy = _tradeWalletMasterCopy;
    }

    function setIsPublic(bool _isPublic) external onlyOwner {
        isPublic = _isPublic;
    }

    function setCanRunProject(address _address, bool _canRunProject) external onlyOwner {
        canRunProject[_address] = _canRunProject;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function registerProject(
        address tokenAddress,
        address dexAddress,
        address pairAddress,
        uint256 frequency,
        uint8 buysPerSell,
        uint16 percentPerTrade
    ) external payable {
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(dexAddress != address(0), "Dex address cannot be zero");
        require(pairAddress != address(0), "Pair address cannot be zero");
        require(dexAddress == v3Router || dexAddress == v2Router, "Invalid dex address");
        require(buysPerSell > 1, "Buys per sell must be greater than 1");
        
        if (isPublic) {
            require(msg.value >= minStartAmount, "Insufficient BNB sent for project registration");
        } else {
            require(msg.sender == this.getOwner(), "Only owner can register projects in private mode");
        }

        // register the project
        proejcts[projectNonce].tokenAddress = tokenAddress;
        projects[projectNonce].dexAddress = dexAddress;
        projects[projectNonce].pairAddress = pairAddress;
        projects[projectNonce].initialBNB = msg.value;
        projects[projectNonce].config.frequency = frequency;
        projects[projectNonce].config.buysPerSell = buysPerSell;
        projects[projectNonce].config.percentPerTrade = percentPerTrade;
        projects[projectNonce].status.isActive = true;
        projects[projectNonce].status.wallets = new address[](0);
        projects[projectNonce].status.remainingBNB = msg.value;

        // Add the project to the token's projects
        tokenProjects[tokenAddress].push(projectNonce);

        // Add the project to the active projects set
        EnumerableSet.add(activeProjects, projectNonce);

        // increment the project nonce
        unchecked {
            ++projectNonce;
        }

        // Create a new trade wallet for the project
        address tradeWallet = cloneTradeWallet();

        // Transfer the initial BNB to the trade wallet
        if (msg.value > 0) {
            (bool success, ) = payable(tradeWallet).call{value: msg.value}("");
            require(success, "Failed to transfer BNB to trade wallet");
        }
    }

    function runBuy(uint256 projectId, uint256 amount, uint256 minOut) external {
        require(canRunProject[msg.sender], 'Permission denied');
        require(projects[projectId].status.isActive == true, "Project is not active");
        require(projects[projectId].lastTradeTime + projects[projectId].config.frequency <= block.timestamp, "Trade frequency not met");

        // create new trade wallet to buy tokens
        address tradeWallet = cloneTradeWallet();

        // take fee
        uint256 buyAmount = _takeFee(amount);

        bytes memory data = projects[projectId].dexAddress == v2Router ?
            _buyV2Data(projects[projectId].tokenAddress, buyAmount, minOut, tradeWallet) :
            _buyV3Data(projects[projectId].tokenAddress, buyAmount, minOut, tradeWallet);

        // get token amount before buy
        uint256 tokenAmountBefore = IERC20(projects[projectId].tokenAddress).balanceOf(tradeWallet);

        // execute buy on trade wallet
        TradeWallet(tradeWallet).execute{value: buyAmount}(projects[projectId].dexAddress, data);

        // get token amount after buy
        uint256 tokenAmountAfter = IERC20(projects[projectId].tokenAddress).balanceOf(tradeWallet);

        // calculate token amount bought
        uint256 tokenAmountBought = tokenAmountAfter - tokenAmountBefore;

        // update info
        unchecked {
            projects[projectId].status.totalTokenVolume += tokenAmountBought;
            projects[projectId].status.totalBNBVolume += buyAmount;
            projects[projectId].status.remainingBNB -= buyAmount;
            projects[projectId].status.consecutiveBuys += 1;
        }

        projects[projectId].status.lastTradeTime = block.timestamp;
        projects[projectId].status.wallets.push(tradeWallet);
        EnumerableSet.add(projects[projectId].status.activeWallets, tradeWallet);   
    }

    function runSell(uint256 projectId, uint256 amount, uint256 minOut) external {
        require(canRunProject[msg.sender], 'Permission denied');
        require(projects[projectId].status.isActive == true, "Project is not active");
        require(projects[projectId].lastTradeTime + projects[projectId].config.frequency <= block.timestamp, "Trade frequency not met");

        // we are selling this time, choose `consecutiveBuys` wallets to batch together and sell
        address[] memory walletsToSell = EnumerableSet.values(projects[projectId].status.activeWallets);
        uint len = walletsToSell.length;
        address finalWallet = walletsToSell[len - 1];
        for (uint i = 0; i < len - 1;) {

            // get balance
            uint bal = IERC20(projects[projectId].tokenAddress).balanceOf(walletsToSell[i]);
            if (bal > 0) {
                // send these tokens into the final wallet in the list
                TradeWallet(walletsToSell[i]).execute(
                    projects[projectId].tokenAddress,
                    abi.encodeWithSignature(
                        "transfer(address,uint256)",
                        finalWallet,
                        bal - 2 // send all but 2 tokens to avoid rounding errors and improve holder count
                    )
                );
            }
            unchecked { ++i; }
        }

        uint256 bal = IERC20(projects[projectId].tokenAddress).balanceOf(finalWallet);
        if (bal > 0) {

            // prepare approval for v2 router
            TradeWallet(finalWallet).execute(
                projects[projectId].tokenAddress,
                abi.encodeWithSignature(
                    "approve(address,uint256)",
                    projects[projectId].dexAddress,
                    bal - 2
                )
            );

            bytes memory data = projects[projectId].dexAddress == v2Router ?
                _sellV2Data(projects[projectId].tokenAddress, bal - 2, minOut, address(this)) :
                _sellV3Data(projects[projectId].tokenAddress, bal - 2, minOut, address(this));
            
            // bnb balance before
            uint256 bnbBefore = address(this).balance;

            // execute sell on trade wallet
            TradeWallet(finalWallet).execute(projects[projectId].dexAddress, data);

            // bnb balance after
            uint256 bnbAfter = address(this).balance;
            uint256 bnbReceived = bnbAfter - bnbBefore;
            
            // disable bot if bnb received is less than minAmountToTrade
            if ((projects[projectId].status.remainingBNB + bnbReceived) <= minAmountToTrade) {

                // turn off project, collect remaining bnb
                projects[projectId].status.isActive = false;

                // remove project from active projects set
                EnumerableSet.remove(activeProjects, projectId);
                
                // transfer remaining bnb to fee receiver
                (bool success, ) = payable(feeReceiver).call{value: projects[projectId].status.remainingBNB}("");
                require(success, "Failed to transfer remaining BNB to fee receiver");

                // set remaining bnb to 0
                projects[projectId].status.remainingBNB = 0;

            } else {

                // update info
                unchecked {
                    projects[projectId].status.remainingBNB += bnbReceived;
                    projects[projectId].status.consecutiveBuys = 0;
                    projects[projectId].status.lastTradeTime = block.timestamp;
                }
            }
        }

        for (uint i = 0; i < len;) {
            // remove the wallets from the active wallets set
            EnumerableSet.remove(projects[projectId].status.activeWallets, walletsToSell[i]);
            unchecked { ++i; }
        }

    }

    function isTimeToTrade(uint256 projectId) external view returns (bool) {
        return projects[projectId].lastTradeTime + projects[projectId].config.frequency <= block.timestamp;
    }

    function shouldBuy(uint256 projectId) external view returns (bool) {
        return projects[projectId].status.consecutiveBuys < projects[projectId].config.buysPerSell;
    }

    function getAmountToSell(uint256 projectId) public view returns (uint256 totalAmount) {
        address[] memory walletsToSell = EnumerableSet.values(projects[projectId].status.activeWallets);
        uint len = walletsToSell.length;
        for (uint i = 0; i < len;) {            
            unchecked {
                totalAmount += IERC20(projects[projectId].tokenAddress).balanceOf(walletsToSell[i]);
            }
            unchecked { ++i; }
        }
    }

    function getBuyAmount(uint256 projectId) public view returns (uint256) {

        // get remaining bnb
        uint256 remainingBNB = projects[projectId].status.remainingBNB;

        // get initial bnb
        uint256 initialBNB = projects[projectId].initialBNB;

        // get percent per trade
        uint16 percentPerTrade = projects[projectId].config.percentPerTrade;

        // determine percentage of initial bnb to use for buy
        uint256 buyAmount = (initialBNB * percentPerTrade) / FEE_DENOMINATOR;
        if (buyAmount > remainingBNB) {
            buyAmount = remainingBNB;
        }
    }

    function getBuyAmountLessFee(uint256 projectId) external view returns (uint256) {
        uint256 buyAmount = getBuyAmount(projectId);
        uint256 fee = (buyAmount * platformFee) / FEE_DENOMINATOR;
        return buyAmount - fee;
    }

    function _takeFee(uint256 amount) internal returns (uint256) {
        uint256 fee = (amount * platformFee) / FEE_DENOMINATOR;
        if (fee > 0) {
            (bool success, ) = payable(feeReceiver).call{value: fee}("");
            require(success, "Failed to transfer fee to receiver");
        }
        return amount - fee;
    }

    function _buyV3Data(address tokenAddress, uint256 amount, uint256 minOut, address to) internal returns (bytes memory) {
        ExactInputSingleParams memory params = ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: tokenAddress,
            fee: 1000,
            recipient: to,
            amountIn: amount,
            amountOutMinimum: minOut,
            sqrtPriceLimitX96: 0
        });

        return abi.encodeWithSignature("exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))", params);
    }

    function _sellV3Data(address tokenAddress, uint256 amount, uint256 minOut, address to) internal returns (bytes memory) {
        ExactInputSingleParams memory params = ExactInputSingleParams({
            tokenIn: tokenAddress,
            tokenOut: WETH,
            fee: 1000,
            recipient: to,
            amountIn: amount,
            amountOutMinimum: minOut,
            sqrtPriceLimitX96: 0
        });

        return abi.encodeWithSignature("exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))", params);
    }

    function _buyV2Data(address tokenAddress, uint256 amount, uint256 minOut, address to) internal returns (bytes memory) {

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = tokenAddress;

        // get data
        bytes memory data = abi.encodeWithSignature(
            "swapExactETHForTokensSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)",
            minOut,
            path,
            to,
            block.timestamp + 100
        );

        // clear memory
        delete path;

        return data;
    }

    function _sellV2Data(address tokenAddress, uint256 amount, uint256 minOut, address to) internal returns (bytes memory) {
        
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = WETH;

        bytes memory data = abi.encodeWithSignature(
            "swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)",
            amount,
            minOut,
            path,
            to,
            block.timestamp + 100
        );

        // clear memory
        delete path;

        return data;
    }

    function getTokenProjects(address tokenAddress) external view returns (uint256[] memory) {
        return tokenProjects[tokenAddress];
    }

    function getActiveProjects() external view returns (uint256[] memory) {
        return EnumerableSet.values(activeProjects);
    }

    function getProjectInfo(uint256 projectId) external view returns (
        address tokenAddress,
        address dexAddress,
        address pairAddress,
        uint256 initialBNB
    ) {
        tokenAddress = projects[projectId].tokenAddress;
        dexAddress = projects[projectId].dexAddress;
        pairAddress = projects[projectId].pairAddress;
        initialBNB = projects[projectId].initialBNB;
    }

    function getProjectStatus(uint256 projectId) external view returns (
        bool isActive,
        uint256 lastTradeTime,
        uint256 remainingBNB,
        uint256 totalTokenVolume,
        uint256 totalBNBVolume,
        uint8 consecutiveBuys
    ) {
        isActive = projects[projectId].status.isActive;
        lastTradeTime = projects[projectId].status.lastTradeTime;
        remainingBNB = projects[projectId].status.remainingBNB;
        totalTokenVolume = projects[projectId].status.totalTokenVolume;
        totalBNBVolume = projects[projectId].status.totalBNBVolume;
        consecutiveBuys = projects[projectId].status.consecutiveBuys;
    }

    function getProjectWallets(uint256 projectId) external view returns (address[] memory) {
        return projects[projectId].status.wallets;
    }

    function getProjectActiveWallets(uint256 projectId) external view returns (address[] memory) {
        return EnumerableSet.values(projects[projectId].status.activeWallets);
    }

    function getProjectConfig(uint256 projectId) external view returns (
        uint256 frequency,
        uint8 buysPerSell,
        uint16 percentPerTrade
    ) {
        frequency = projects[projectId].config.frequency;
        buysPerSell = projects[projectId].config.buysPerSell;
        percentPerTrade = projects[projectId].config.percentPerTrade;
    }

    function cloneTradeWallet() internal returns (address) {
        address tradeWallet = _clone(tradeWalletMasterCopy);
        TradeWallet(tradeWallet).__init__();
        return tradeWallet;
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function _clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    receive() external payable {

    }
}