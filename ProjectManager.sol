//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;


contract ProjectManagerData {

    uint256 public initialBNB; // starting bnb amount

    address public database; // database

    uint256 public projectId; // projectNonce value

    address public owner; // owner of contract

    bool public isActive; // is an active project

    bool public isPaused; // set is paused

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only Owner');
        _;
    }
}


/**
    Stores funds and some state for projects
 */
contract ProjectManager {

    function addFunds() external payable {
        initialBNB += msg.value;
    }

    function setIsPaused(bool isPaused_) external onlyOwner {
        isPaused = isPaused_;
    }
    
    function endBot() external onlyOwner {
        require(isActive, 'Already Disabled');

        isActive = false;
        if (address(this).balance > 0) {
            (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
            require(s);
        }
    }

    function _removeProject() internal {
        database.deActivateProject(projectId);
    }

    receive() external payable {}
}