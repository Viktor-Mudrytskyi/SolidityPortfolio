// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// TODO
// name VikToken
// symbol VIK
// decimals 18 (is also default in Zeppelin) ERC20

// @dev
// Implementation of the ERC20 abstract contract.
contract VikToken is ERC20 {
    string private constant NAME = "VikToken";
    string private constant SYMBOL = "VIK";
    uint256 private immutable i_initialSupply;

    constructor(uint256 initialSupply) ERC20(NAME, SYMBOL) {
        i_initialSupply = initialSupply;
    }

    function getInitialSupply() public view returns (uint256) {
        return i_initialSupply;
    }
}
