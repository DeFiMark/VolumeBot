//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;


/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 => uint256) _positions;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._positions[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

contract TradeWalletData {
    address public manager;
}

contract TradeWallet is TradeWalletData {

    function __init__() external {
        require(manager == address(0), "Already initialized");
        manager = msg.sender;
    }

    function execute(address target, bytes calldata data) external payable {
        require(msg.sender == manager, "Only manager can execute");
        (bool success, ) = target.call{value: msg.value}(data);
        require(success, "Execution failed");
    }

    receive() external payable {
        // Accept ETH deposits
    }
}


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

interface ITradeWallet {
    function withdrawETH(address to, uint256 amount) external;
    function execute(address target, bytes calldata data) external payable;
}

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
        uint24 fee;
        Config config;
        Status status;
    }

    mapping ( uint256 => Project ) private projects; // projectId => Project

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

    uint32 public buyAmountRandomnessShifter = 5_000; // up to +50% or -50%

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

    function withdrawETH(address to, uint amount) external onlyOwner {
        (bool s,) = payable(to).call{value: amount}("");
        require(s);
    }

    function withdrawTokens(address token, address to, uint amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function withdrawETHFromTradeWallet(address tradeWallet, address to, uint256 amount) external onlyOwner {
        ITradeWallet(tradeWallet).withdrawETH(to, amount);
    }

    function directCallToTradeWallet(address tradeWallet, address target, bytes calldata data) external payable onlyOwner {
        ITradeWallet(tradeWallet).execute{value: msg.value}(target, data);
    }

    function setBuyAmountRandomnessShifter(uint32 newShifter) external onlyOwner {
        require(newShifter < FEE_DENOMINATOR, 'Shifter Too High');
        buyAmountRandomnessShifter = newShifter;
    }

    function deActivateProject(uint256 projectId) external onlyOwner {
        require(
            projects[projectId].status.isActive == true,
            'Not Active'
        );

        // turn off project, collect remaining bnb
        projects[projectId].status.isActive = false;

        // remove project from active projects set
        EnumerableSet.remove(activeProjects, projectId);
        
        // transfer remaining bnb to fee receiver
        (bool success, ) = payable(feeReceiver).call{value: projects[projectId].status.remainingBNB}("");
        require(success, "Failed to transfer remaining BNB to fee receiver");

        // set remaining bnb to 0
        projects[projectId].status.remainingBNB = 0;
    }

    function registerProject(
        address tokenAddress,
        address dexAddress,
        address pairAddress,
        uint24 fee,
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
        projects[projectNonce].tokenAddress = tokenAddress;
        projects[projectNonce].dexAddress = dexAddress;
        projects[projectNonce].pairAddress = pairAddress;
        projects[projectNonce].fee = fee;
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
    }

    function runBuy(uint256 projectId, uint256 amount, uint256 minOut) external {
        require(canRunProject[msg.sender], 'Permission denied');
        require(projects[projectId].status.isActive == true, "Project is not active");
        require(projects[projectId].status.lastTradeTime + projects[projectId].config.frequency <= block.timestamp, "Trade frequency not met");

        // create new trade wallet to buy tokens
        address tradeWallet = cloneTradeWallet();

        // take fee
        uint256 buyAmount = _takeFee(amount);

        bytes memory data = projects[projectId].dexAddress == v2Router ?
            _buyV2Data(projects[projectId].tokenAddress, minOut, tradeWallet) :
            _buyV3Data(projects[projectId].tokenAddress, buyAmount, minOut, tradeWallet, projects[projectId].fee);

        // get token amount before buy
        uint256 tokenAmountBefore = IERC20(projects[projectId].tokenAddress).balanceOf(tradeWallet);

        // execute buy on trade wallet
        TradeWallet(payable(tradeWallet)).execute{value: buyAmount}(projects[projectId].dexAddress, data);

        // get token amount after buy
        uint256 tokenAmountAfter = IERC20(projects[projectId].tokenAddress).balanceOf(tradeWallet);

        // calculate token amount bought
        uint256 tokenAmountBought = tokenAmountAfter - tokenAmountBefore;

        // update info
        unchecked {
            projects[projectId].status.totalTokenVolume += tokenAmountBought;
            projects[projectId].status.totalBNBVolume += buyAmount;
            projects[projectId].status.remainingBNB -= amount;
            projects[projectId].status.consecutiveBuys += 1;
        }

        projects[projectId].status.lastTradeTime = block.timestamp;
        projects[projectId].status.wallets.push(tradeWallet);
        EnumerableSet.add(projects[projectId].status.activeWallets, tradeWallet);   
    }

    function runSell(uint256 projectId, uint256 minOut) external {
        require(canRunProject[msg.sender], 'Permission denied');
        require(projects[projectId].status.isActive == true, "Project is not active");
        require(projects[projectId].status.lastTradeTime + projects[projectId].config.frequency <= block.timestamp, "Trade frequency not met");

        // we are selling this time, choose `consecutiveBuys` wallets to batch together and sell
        address[] memory walletsToSell = EnumerableSet.values(projects[projectId].status.activeWallets);
        uint len = walletsToSell.length;
        address finalWallet = walletsToSell[len - 1];
        for (uint i = 0; i < len - 1;) {

            // get balance
            uint currentBal = IERC20(projects[projectId].tokenAddress).balanceOf(walletsToSell[i]);
            if (currentBal > 0) {
                // send these tokens into the final wallet in the list
                TradeWallet(payable(walletsToSell[i])).execute(
                    projects[projectId].tokenAddress,
                    abi.encodeWithSignature(
                        "transfer(address,uint256)",
                        finalWallet,
                        currentBal - 2 // send all but 2 tokens to avoid rounding errors and improve holder count
                    )
                );
            }
            unchecked { ++i; }
        }

        uint256 bal = IERC20(projects[projectId].tokenAddress).balanceOf(finalWallet);
        if (bal > 0) {

            // prepare approval for router
            TradeWallet(payable(finalWallet)).execute(
                projects[projectId].tokenAddress,
                abi.encodeWithSignature(
                    "approve(address,uint256)",
                    projects[projectId].dexAddress,
                    bal - 2
                )
            );

            bytes memory data = projects[projectId].dexAddress == v2Router ?
                _sellV2Data(projects[projectId].tokenAddress, bal - 2, minOut, address(this)) :
                _sellV3Data(projects[projectId].tokenAddress, bal - 2, minOut, address(this), projects[projectId].fee);
            
            // bnb balance before
            uint256 bnbBefore = address(this).balance;

            // execute sell on trade wallet
            TradeWallet(payable(finalWallet)).execute(projects[projectId].dexAddress, data);

            // bnb balance after
            uint256 bnbReceived = address(this).balance - bnbBefore;
            
            // disable bot if bnb received is less than minAmountToTrade
            if ((projects[projectId].status.remainingBNB + bnbReceived) <= minAmountToTrade) {

                // turn off project, collect remaining bnb
                projects[projectId].status.isActive = false;

                // remove project from active projects set
                EnumerableSet.remove(activeProjects, projectId);

                // determine the send amount
                uint256 sendAmount = address(this).balance < projects[projectId].status.remainingBNB ? address(this).balance : projects[projectId].status.remainingBNB;
                
                // transfer remaining bnb to fee receiver
                if (sendAmount > 0) {
                    (bool success, ) = payable(feeReceiver).call{value: sendAmount}("");
                    require(success, "Failed to transfer remaining BNB to fee receiver");
                }

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

    function addToProjectsValue(uint256 projectId) external payable {
        require(projects[projectId].status.isActive == true, "Project is not active");

        unchecked {
            projects[projectId].status.remainingBNB += msg.value;
            projects[projectId].initialBNB += msg.value;
        }
    }

    function isTimeToTrade(uint256 projectId) external view returns (bool) {
        return projects[projectId].status.lastTradeTime + projects[projectId].config.frequency <= block.timestamp;
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
        if (remainingBNB == 0) {
            return 0;
        }

        // get percent per trade
        uint16 percentPerTrade = projects[projectId].config.percentPerTrade;

        // determine percentage of initial bnb to use for buy
        uint256 buyAmount = (projects[projectId].initialBNB * percentPerTrade) / FEE_DENOMINATOR;

        if (buyAmountRandomnessShifter == 0) {
            return buyAmount > remainingBNB ? remainingBNB : buyAmount;
        }

        // change this buy amount either +- the shifter value for a sense of randomness
        uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(block.timestamp, projectNonce, buyAmount)));

        // get the percentage change
        uint32 percentageChange = uint32(( pseudoRandom % buyAmountRandomnessShifter ));

        // get either positive or negative change
        if (( pseudoRandom % 2 ) == 0) {
            // positive
            buyAmount += ( ( buyAmount * percentageChange ) / FEE_DENOMINATOR );
        } else {
            // negative
            buyAmount -= ( ( buyAmount * percentageChange ) / FEE_DENOMINATOR );
        }

        if (buyAmount > remainingBNB) {
            if (projects[projectId].status.consecutiveBuys < ( projects[projectId].config.buysPerSell - 1 )) {
                // we have more than 1 buy to go
                buyAmount = remainingBNB / 2;
            } else {
                // this is the last buy of this cycle, use the rest of the bnb
                buyAmount = remainingBNB;
            }
        }

        return buyAmount;
    }

    function getBuyAmountLessFee(uint256 projectId) external view returns (uint256) {
        return getBuyAmount(projectId);
    }

    function _takeFee(uint256 amount) internal returns (uint256) {
        uint256 fee = (amount * platformFee) / FEE_DENOMINATOR;
        if (fee > 0) {
            (bool success, ) = payable(feeReceiver).call{value: fee}("");
            require(success, "Failed to transfer fee to receiver");
        }
        return amount - fee;
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
        uint256 initialBNB,
        uint24 fee
    ) {
        tokenAddress = projects[projectId].tokenAddress;
        dexAddress = projects[projectId].dexAddress;
        pairAddress = projects[projectId].pairAddress;
        initialBNB = projects[projectId].initialBNB;
        fee = projects[projectId].fee;
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
        TradeWallet(payable(tradeWallet)).__init__();
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