//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

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

    function withdrawETH(address to, uint256 amount) external {
        require(msg.sender == manager, "Only manager can call");
        (bool s,) = payable(to).call{value: amount}("");
        require(s);
    }

    receive() external payable {
        // Accept ETH deposits
    }

}