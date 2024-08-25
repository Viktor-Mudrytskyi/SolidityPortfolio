// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Box {
    uint256 private _value;

    constructor(uint256 initial) {
        _value = initial;
    }

    function upgrade(uint256 newValue) public {
        _value = newValue;
    }

    function value() public view returns (uint256) {
        return _value;
    }
}
