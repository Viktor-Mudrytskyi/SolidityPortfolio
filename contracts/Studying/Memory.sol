// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MemoryContract {
    function work(
        string memory /*_data*/
    ) external pure returns (bytes32 data) {
        assembly {
            // Start of the free memory pointer 0x40=64
            let ptr := mload(0x40)
            data := mload(sub(ptr, 32))
        }
    }

    function work2(
        uint8[3] memory /*_data*/
    ) external pure returns (bytes memory) {
        return msg.data;
    }

    function getSelectorForWork2() external pure returns (bytes4) {
        return bytes4(keccak256(bytes("work2(uint8[3])")));
    }

    function getSelectorForThis() external pure returns (bytes4) {
        // Also a way to extract signature
        return bytes4(msg.data[0:4]);
    }

    function work3(
        string calldata /*_data*/
    ) external pure returns (bytes32 _el1) {
        assembly {
            _el1 := calldataload(add(32, add(4, 32)))
        }
    }
}
