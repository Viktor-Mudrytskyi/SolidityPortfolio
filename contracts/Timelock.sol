// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Timelock is Ownable {
    uint8 public constant MIN_DELAY = 10;
    uint32 public constant MAX_DELAY = 1 days;
    uint32 public constant GRACE_PERIOD = 1 days;

    mapping(bytes32 => bool) public s_queue;
    string public message;
    uint256 public amount;

    event Queued(bytes32 indexed txId);
    event Discarded(bytes32 indexed txId);
    event Executed(bytes32 indexed txId);

    constructor() Ownable(msg.sender) {}

    function demo(string calldata _msg) external payable {
        message = _msg;
        amount = msg.value;
    }

    function addToQueue(
        address _to,
        string calldata _func,
        bytes calldata _data,
        uint256 _value,
        uint256 _timestamp
    ) external onlyOwner returns (bytes32) {
        require(
            _timestamp > block.timestamp + MIN_DELAY &&
                _timestamp < block.timestamp + MAX_DELAY,
            "Invalid timestamp"
        );
        bytes32 trxId = keccak256(
            abi.encode(_to, _func, _data, _value, _timestamp)
        );

        require(!s_queue[trxId], "Already queued");

        s_queue[trxId] = true;

        emit Queued(trxId);
        return trxId;
    }

    function execute(
        address _to,
        string calldata _func,
        bytes calldata _data,
        uint256 _value,
        uint256 _timestamp
    ) external payable onlyOwner returns (bytes memory) {
        require(_timestamp <= block.timestamp, "Too early");
        require(_timestamp + GRACE_PERIOD > block.timestamp, "Tx expired");
        bytes32 trxId = keccak256(
            abi.encode(_to, _func, _data, _value, _timestamp)
        );

        require(s_queue[trxId], "Not queued");

        delete s_queue[trxId];
        bytes memory data;
        if (bytes(_func).length > 0) {
            data = abi.encodeWithSignature(_func, _data);
        } else {
            data = _data;
        }

        (bool success, bytes memory response) = _to.call{value: _value}(data);
        require(success, "Call failed");
        emit Executed(trxId);
        return response;
    }

    function discard(bytes32 _trxId) external onlyOwner {
        require(s_queue[_trxId], "Not queued");
        delete s_queue[_trxId];
        emit Discarded(_trxId);
    }

    function getNextTimestamp() external view returns (uint256) {
        return block.timestamp + MIN_DELAY + 30;
    }

    function prepareData(
        string calldata _msg
    ) external pure returns (bytes memory) {
        return abi.encode(_msg);
    }
}
