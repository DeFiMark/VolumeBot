/**
 *Submitted for verification at BscScan.com on 2025-05-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDEXTrades {
    function isDEXSupported(address dexAddress) external view returns (bool);
    function getBuyData(address dexAddress, address tokenAddress, address to, uint256 amount, uint256 minOut, uint24 fee) external view returns (bytes memory);
    function getSellData(address dexAddress, address tokenAddress, uint256 amount, uint256 minOut, address to, uint24 fee) external view returns (bytes memory);
}

/**
    This contract exists to easily add support for different DEXes and pair types, without needing to relaunch the main DB contract
 */
contract DEXTradeRawDataFetcher is IDEXTrades {

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

    // maps a dex to if its supported
    mapping ( address => bool ) private _supported;

    constructor() {
        _supported[v3Router] = true;
        _supported[v2Router] = true;
    }

    function isDEXSupported(address dexAddress) external view override returns (bool) {
        return _supported[dexAddress];
    }

    function getBuyData(address dexAddress, address tokenAddress, address to, uint256 amount, uint256 minOut, uint24 fee) external view override returns (bytes memory) {
        if (!_supported[dexAddress]) {
            return "";
        }
        
        if (dexAddress == v3Router) {
            return _buyV3Data(tokenAddress, amount, minOut, to, fee);
        } else {
            return _buyV2Data(tokenAddress, minOut, to);
        }
    }

    function getSellData(address dexAddress, address tokenAddress, uint256 amount, uint256 minOut, address to, uint24 fee) external view override returns (bytes memory) {
        if (!_supported[dexAddress]) {
            return "";
        }
        
        if (dexAddress == v3Router) {
            return _sellV3Data(tokenAddress, amount, minOut, to, fee);
        } else {
            return _sellV2Data(tokenAddress, amount, minOut, to);
        }
    }

    function _buyV3Data(address tokenAddress, uint256 amount, uint256 minOut, address to, uint24 fee) internal pure returns (bytes memory) {
        ExactInputSingleParams memory params = ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: tokenAddress,
            fee: fee,
            recipient: to,
            amountIn: amount,
            amountOutMinimum: minOut,
            sqrtPriceLimitX96: 0
        });

        return abi.encodeWithSignature("exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))", params);
    }

    function _sellV3Data(address tokenAddress, uint256 amount, uint256 minOut, address to, uint24 fee) internal pure returns (bytes memory) {
        ExactInputSingleParams memory params = ExactInputSingleParams({
            tokenIn: tokenAddress,
            tokenOut: WETH,
            fee: fee,
            recipient: to,
            amountIn: amount,
            amountOutMinimum: minOut,
            sqrtPriceLimitX96: 0
        });

        return abi.encodeWithSignature("exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))", params);
    }

    function _buyV2Data(address tokenAddress, uint256 minOut, address to) internal view returns (bytes memory) {

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = tokenAddress;

        // get data
        bytes memory data = abi.encodeWithSignature(
            "swapExactETHForTokensSupportingFeeOnTransferTokens(uint256,address[],address,uint256)",
            minOut,
            path,
            to,
            block.timestamp + 100
        );

        // clear memory
        delete path;

        return data;
    }

    function _sellV2Data(address tokenAddress, uint256 amount, uint256 minOut, address to) internal view returns (bytes memory) {
        
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

}