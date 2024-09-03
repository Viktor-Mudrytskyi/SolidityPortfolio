// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Timelock {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        bytes32 uid;
    }

    uint8 public constant MIN_DELAY = 10;
    uint32 public constant MAX_DELAY = 1 days;
    uint32 public constant GRACE_PERIOD = 1 days;
    uint8 public constant CONFIRMATIONS_REQUIRED = 3;

    address[] public owners;
    mapping(address => bool) public ownersMap;
    mapping(bytes32 => bool) public s_queue;
    mapping(bytes32 => mapping(address => bool)) public s_confirmations;
    mapping(bytes32 => Transaction) public s_transactions;

    // For demo
    string public message;
    uint256 public amount;

    modifier onlyOwner() {
        require(ownersMap[msg.sender], "Only owner");
        _;
    }

    event Queued(bytes32 indexed txId);
    event Discarded(bytes32 indexed txId);
    event Executed(bytes32 indexed txId);

    constructor(address[] memory _owners) {
        uint256 length = _owners.length;
        require(length >= CONFIRMATIONS_REQUIRED, "Not enough owners");
        for (uint256 i = 0; i < length; i++) {
            address current = _owners[i];
            require(current != address(0), "Zero address provided");
            require(ownersMap[current] == false, "Duplicate owner");
            ownersMap[current] = true;
            owners.push(current);
        }
    }

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
        s_transactions[trxId] = Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 0,
            uid: trxId
        });

        emit Queued(trxId);
        return trxId;
    }

    function confirm(bytes32 _txId) external onlyOwner {
        require(s_queue[_txId], "Not queued");
        require(!s_confirmations[_txId][msg.sender], "Already confirmed");
        Transaction storage transaction = s_transactions[_txId];
        transaction.confirmations++;
        s_confirmations[_txId][msg.sender] = true;
    }

    function cancelConfirmation(bytes32 _txId) external onlyOwner {
        require(s_queue[_txId], "Not queued");
        require(s_confirmations[_txId][msg.sender], "Not confirmed");
        Transaction storage transaction = s_transactions[_txId];
        transaction.confirmations++;
        s_confirmations[_txId][msg.sender] = false;
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

        Transaction storage transaction = s_transactions[trxId];
        require(
            transaction.confirmations >= CONFIRMATIONS_REQUIRED,
            "Not enough confirmations"
        );

        require(s_queue[trxId], "Not queued");

        delete s_queue[trxId];

        transaction.executed = true;

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
