/**
 *Submitted for verification at BscScan.com on 2025-05-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface ITask {
    function executeTask(bytes calldata data) external;
    function shouldExecute() external view returns (bool, bytes memory);
}
contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function _preventExecution() internal view {
    // solhint-disable-next-line avoid-tx-origin
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    _preventExecution();
    _;
  }
}


interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDatabase {
    function runSell(uint256 projectId, uint256 minOut) external;
    function runBuy(uint256 projectId, uint256 amount, uint256 minOut) external;
    function isTimeToTrade(uint256 projectId) external view returns (bool);
    function shouldBuy(uint256 projectId) external view returns (bool);
    function getAmountToSell(uint256 projectId) external view returns (uint256 totalAmount);
    function getBuyAmountLessFee(uint256 projectId) external view returns (uint256);
    function getProjectInfo(uint256 projectId) external view returns (
        address tokenAddress,
        address dexAddress,
        address pairAddress,
        uint256 initialBNB,
        uint24 fee
    );
    function getActiveProjects() external view returns (uint256[] memory);
}

interface IPool {
    struct Slot0 {
        uint160 sqrtPriceX96;
        int24  tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        uint32 feeProtocol;
        bool   unlocked;
    }
    function slot0() external view returns (Slot0 memory);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IV2Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

/**
    This contract will handle searching Jackpot games for a game that is able to be ended
    If it is possible to end the game, we will
 */
contract TradeManager is AutomationCompatible, Ownable {

    address public constant v3Router = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
    address public constant v2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint256 public slippage = 95; // 5% slippage
    uint256 public v3Slippage = 90; // 10% slippage

    uint256 public constant SCALE = 1e18;
    uint256 public constant Q192 = 1 << 192;

    IDatabase public database;

    address public forwarder;

    constructor(address database_) {
        database = IDatabase(database_);
    }

    // Transfer contract tokens to an address
    function withdrawToken(address _token, uint256 amount, address to) external onlyOwner {
        TransferHelper.safeTransfer(_token, to, amount);
    }

    // Transfer contract ETH to an address
    function withdrawETH(uint256 amount, address to) external onlyOwner {
        TransferHelper.safeTransferETH(to, amount);
    }

    function setDatabase(address db) external onlyOwner {
        database = IDatabase(db);
    }

    function setSlippage(uint256 _slippage) external onlyOwner {
        require(_slippage <= 100, "Slippage must be less than 100%");
        slippage = _slippage;
    }

    function setV3Slippage(uint256 _slippage) external onlyOwner {
        require(_slippage <= 100, "Slippage must be less than 100%");
        v3Slippage = _slippage;
    }

    function setForwarder(address _forwarder) external onlyOwner {
        forwarder = _forwarder;
    }

    function viewUpkeepResults() external view returns (bool upkeepNeeded, bytes memory performData) {
        uint256[] memory projects = database.getActiveProjects();
        if (projects.length == 0) return (false, "");

        uint256 chosenProjectId = 0;
        for (uint256 i = 0; i < projects.length;) {
            uint256 projectId = projects[i];
            if (database.isTimeToTrade(projectId)) {
                chosenProjectId = projectId;
                break;
            }
            unchecked { ++i; }
        }
        if (chosenProjectId == 0) return (false, "");

        // fetch project info
        (
            address tokenAddress, 
            address dexAddress, 
            address pairAddress,
            ,
        ) = database.getProjectInfo(chosenProjectId);

        // are we buying or selling
        bool isBuying = database.shouldBuy(chosenProjectId);

        if (isBuying) {

            // buying
            uint256 amountToBuy = database.getBuyAmountLessFee(chosenProjectId);

            if (dexAddress == v3Router) {
                uint256 price = getV3Price(tokenAddress, pairAddress);
                uint256 estimatedAmountOut = ( amountToBuy * SCALE ) / price; // 1e18 is the scale factor for v3 prices
                uint256 minOut = ( estimatedAmountOut * v3Slippage ) / 100; // 10% slippage
                return (true, abi.encode(chosenProjectId, amountToBuy, minOut, true));
            } else {
                address[] memory path = new address[](2);
                path[0] = WETH;
                path[1] = tokenAddress;

                uint256[] memory amounts = IV2Router(dexAddress).getAmountsOut(amountToBuy, path); 
                uint256 minOut = ( amounts[1] * slippage ) / 100; // 5% slippage

                return (true, abi.encode(chosenProjectId, amountToBuy, minOut, true));
            }
        } else {

            // selling
            uint256 amountToSell = database.getAmountToSell(chosenProjectId);

            if (dexAddress == v3Router) {
                uint256 price = getV3Price(tokenAddress, pairAddress);
                uint256 estimatedAmountOut = ( amountToSell * price ) / SCALE; // 1e18 is the scale factor for v3 prices
                uint256 minOut = ( estimatedAmountOut * v3Slippage ) / 100; // 10% slippage
                return (true, abi.encode(chosenProjectId, amountToSell, minOut, false));

            } else {

                address[] memory path = new address[](2);
                path[0] = tokenAddress;
                path[1] = WETH;

                uint256[] memory amounts = IV2Router(dexAddress).getAmountsOut(amountToSell, path); 
                uint256 minOut = ( amounts[1] * slippage ) / 100; // 5% slippage

                return (true, abi.encode(chosenProjectId, amountToSell, minOut, false));
            }
        }
    }

    function checkUpkeep(bytes calldata) external override cannotExecute returns (bool upkeepNeeded, bytes memory performData) {
        uint256[] memory projects = database.getActiveProjects();
        if (projects.length == 0) return (false, "");

        uint256 chosenProjectId = 0;
        for (uint256 i = 0; i < projects.length;) {
            uint256 projectId = projects[i];
            if (database.isTimeToTrade(projectId)) {
                chosenProjectId = projectId;
                break;
            }
            unchecked { ++i; }
        }
        if (chosenProjectId == 0) return (false, "");

        // fetch project info
        (
            address tokenAddress, 
            address dexAddress, 
            address pairAddress,,
        ) = database.getProjectInfo(chosenProjectId);

        // are we buying or selling
        bool isBuying = database.shouldBuy(chosenProjectId);

        if (isBuying) {

            // buying
            uint256 amountToBuy = database.getBuyAmountLessFee(chosenProjectId);

            if (dexAddress == v3Router) {
                uint256 price = getV3Price(tokenAddress, pairAddress);
                uint256 estimatedAmountOut = ( amountToBuy * SCALE ) / price; // 1e18 is the scale factor for v3 prices
                uint256 minOut = ( estimatedAmountOut * v3Slippage ) / 100; // 10% slippage
                return (true, abi.encode(chosenProjectId, amountToBuy, minOut, true));
            } else {
                address[] memory path = new address[](2);
                path[0] = WETH;
                path[1] = tokenAddress;

                uint256[] memory amounts = IV2Router(dexAddress).getAmountsOut(amountToBuy, path); 
                uint256 minOut = ( amounts[1] * slippage ) / 100; // 5% slippage

                return (true, abi.encode(chosenProjectId, amountToBuy, minOut, true));
            }
        } else {

            // selling
            uint256 amountToSell = database.getAmountToSell(chosenProjectId);

            if (dexAddress == v3Router) {
                uint256 price = getV3Price(tokenAddress, pairAddress);
                uint256 estimatedAmountOut = ( amountToSell * price ) / SCALE; // 1e18 is the scale factor for v3 prices
                uint256 minOut = ( estimatedAmountOut * v3Slippage ) / 100; // 10% slippage
                return (true, abi.encode(chosenProjectId, amountToSell, minOut, false));

            } else {

                address[] memory path = new address[](2);
                path[0] = tokenAddress;
                path[1] = WETH;

                uint256[] memory amounts = IV2Router(dexAddress).getAmountsOut(amountToSell, path); 
                uint256 minOut = ( amounts[1] * slippage ) / 100; // 5% slippage

                return (true, abi.encode(chosenProjectId, amountToSell, minOut, false));
            }
        }
    }

    function performUpkeep(bytes calldata performData) external {
        require(msg.sender == forwarder || msg.sender == this.getOwner(), 'Only Forwarder');
        (uint256 projectId, uint256 amount, uint256 minOut, bool isBuying) = abi.decode(performData, (uint256, uint256, uint256, bool));
        if (isBuying) {
            database.runBuy(projectId, amount, minOut);
        } else {
            database.runSell(projectId, minOut);
        }
    }

    /// @param token   list of input tokens to price
    /// @param lp      list of corresponding LP (pool) addresses for each token
    function getV3Price(
        address token,
        address lp
    ) public view returns (uint256 price) {

        IPool pool = IPool(lp);
        IPool.Slot0 memory s = pool.slot0();
        address t0 = pool.token0();
        address t1 = pool.token1();

        // sqrtPriceX96 is Q96: sqrt(token1/token0) * 2^96
        uint256 sp = uint256(s.sqrtPriceX96);

        // priceQ192 = (sqrtPriceX96)^2 → Q192 = price(token1/token0) * 2^192
        uint256 priceQ192 = sp * sp;

        if (token == t0) {
            // user asks "what is 1 t0 worth in t1?"
            // rawPrice = priceQ192 / 2^192
            // to scale to 1e18 fixed‐point: (priceQ192 * SCALE) / 2^192
            price = (priceQ192 * SCALE) / Q192;
        } else if (token == t1) {
            // user asks "what is 1 t1 worth in t0?"
            // invert the ratio: rawInv = 2^192 / priceQ192
            // then scale: (2^192 * SCALE) / priceQ192
            price = (Q192 * SCALE) / priceQ192;
        } else {
            // should never happen, but guard against bad inputs
            price = 0;
        }
    }
}