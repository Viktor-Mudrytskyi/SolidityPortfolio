// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MyContract {
    address private s_otherContract;

    event Response(string response);

    constructor(address _otherContract) {
        s_otherContract = _otherContract;
    }

    function callReceive() external payable {
        (bool success, ) = s_otherContract.call{value: msg.value}("");
        require(success, "Cant call");
    }

    function callSetNameSelector(string calldata _name) external {
        (bool success, bytes memory response) = s_otherContract.call(
            abi.encodeWithSelector(AnotherContract.setName.selector, _name)
        );
        require(success, "Cant call");
        emit Response(abi.decode(response, (string)));
    }

    function callSetNameSig(string calldata _name) external {
        (bool success, bytes memory response) = s_otherContract.call(
            abi.encodeWithSignature("setName(string)", _name)
        );
        require(success, "Cant call");
        emit Response(abi.decode(response, (string)));
    }
}

contract AnotherContract {
    string public name;
    mapping(address => uint256) public balances;

    function setName(string calldata _name) public returns (string memory) {
        name = _name;
        return _name;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}
