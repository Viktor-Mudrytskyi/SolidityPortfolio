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

    uint256 private s_totalSupply;
    mapping(address => uint256) private s_balanceOf;

    constructor(uint256 initialSupply) ERC20(NAME, SYMBOL) {
        i_initialSupply = initialSupply;
        _mintToken(msg.sender, i_initialSupply);
    }

    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        address from = msg.sender;
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        uint256 senderBalance = s_balanceOf[from];
        if (senderBalance < value) {
            revert ERC20InsufficientBalance(from, senderBalance, value);
        }
        unchecked {
            // Overflow not possible: value <= senderBalance <= totalSupply.
            s_balanceOf[from] = senderBalance - value;
            s_balanceOf[to] = s_balanceOf[to] + value;
        }
        emit Transfer(from, to, value);
        return true;
    }

    function _mintToken(address to, uint256 amount) internal {
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        s_totalSupply += amount;
        s_balanceOf[to] = s_balanceOf[to] + amount;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return s_balanceOf[account];
    }

    function totalSupply() public view override returns (uint256) {
        return s_totalSupply;
    }

    function getInitialSupply() public view returns (uint256) {
        return i_initialSupply;
    }
}
