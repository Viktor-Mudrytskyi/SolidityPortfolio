// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MerkleTree {
    // keccak256 hash is always 32 bytes
    bytes32[] public hashes;
    string[4] public transactions = [
        "TX1: 1 -> 2",
        "TX2: 2 -> 3",
        "TX3: 3 -> 4",
        "TX4: 4 -> 1"
    ];

    constructor() {
        for (uint256 index = 0; index < transactions.length; index++) {
            hashes.push(keccak256(abi.encode(transactions[index])));
        }

        uint256 count = transactions.length;
        uint256 offset = 0;

        while (count > 0) {
            for (uint256 i = 0; i < count - 1; i += 2) {
                hashes.push(
                    keccak256(
                        abi.encode(hashes[offset + i], hashes[offset + i + 1])
                    )
                );
            }

            offset += count;
            count /= 2;
        }
    }

    function verify(
        string memory _transaction,
        uint256 _index,
        bytes32 _root,
        bytes32[] memory _proof
    ) public pure returns (bool) {
        bytes32 hash = keccak256(abi.encode(_transaction));
        for (uint256 i = 0; i < _proof.length; i++) {
            bytes32 element = _proof[i];
            if (_index % 2 == 0) {
                hash = keccak256(abi.encode(hash, element));
            } else {
                hash = keccak256(abi.encode(element, hash));
            }
            _index /= 2;
        }

        return hash == _root;
    }

    function getHashes() public view returns (bytes32[] memory) {
        return hashes;
    }

    function getHashesLength() public view returns (uint256) {
        return hashes.length;
    }
}
