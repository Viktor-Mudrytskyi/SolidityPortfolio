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
    mapping(address => mapping(address => uint256)) private s_allowances;

    constructor(uint256 initialSupply) ERC20(NAME, SYMBOL) {
        i_initialSupply = initialSupply;
        _mintToken(msg.sender, i_initialSupply);
    }

    function transfer(
        address _to,
        uint256 _value
    ) public override returns (bool) {
        address from = msg.sender;
        _transferToken(from, _to, _value);
        emit Transfer(from, _to, _value);
        return true;
    }

    function approve(
        address _spender,
        uint256 _value
    ) public override returns (bool) {
        s_allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _transferToken(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        if (_from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (_to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        uint256 senderBalance = s_balanceOf[_from];
        if (senderBalance < _value) {
            revert ERC20InsufficientBalance(_from, senderBalance, _value);
        }
        unchecked {
            // Overflow not possible: value <= senderBalance <= totalSupply.
            s_balanceOf[_from] = senderBalance - _value;
            s_balanceOf[_to] = s_balanceOf[_to] + _value;
        }
    }

    function _mintToken(address _to, uint256 _amount) internal {
        if (_to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        s_totalSupply += _amount;
        s_balanceOf[_to] = s_balanceOf[_to] + _amount;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view override returns (uint256) {
        return s_allowances[_owner][_spender];
    }

    function balanceOf(
        address _account
    ) public view override returns (uint256) {
        return s_balanceOf[_account];
    }

    function totalSupply() public view override returns (uint256) {
        return s_totalSupply;
    }

    function getInitialSupply() public view returns (uint256) {
        return i_initialSupply;
    }
}
