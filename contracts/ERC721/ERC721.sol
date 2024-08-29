// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721Metadata} from "./IERC721Metadata.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";

import "contracts/ERC165/ERC165.sol";
import "contracts/ERC721/IERC721.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721 is IERC721Metadata, ERC165 {
    using Strings for uint;
    string public s_name;
    string public s_symbol;

    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) internal _owners;
    mapping(uint256 => address) internal _tokenApprovals;
    // this(operator) can operate all tokens of this address (true or false)
    //          |                       /
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    modifier _requireMinted(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        _;
    }

    error NotMinted(uint256 tokenId);
    error TransferNotApproved(uint256 tokenId, address from);
    error InvalidAddress(address value);
    error NonERC721Receiver(address sender, address receiver, uint256 tokenId);
    error NotAnOwner(address from, address to, uint256 tokenId);

    constructor(string memory _name, string memory _symbol) {
        s_name = _name;
        s_symbol = _symbol;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert TransferNotApproved(tokenId, msg.sender);
        }
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert TransferNotApproved(tokenId, msg.sender);
        }
        _safeTransfer(from, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
    }

    function balanceOf(address owner) external view returns (uint256) {
        if (owner == address(0)) revert InvalidAddress(owner);
        return _balances[owner];
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = _owners[tokenId];
        require(
            owner == msg.sender || isApprovedForAll(msg.sender, owner),
            "ERC721: caller is not token owner nor approved"
        );
        require(to != owner, "ERC721: approval to current owner");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        address owner = ownerOf(tokenId);
        delete _tokenApprovals[tokenId];
        _balances[owner]--;
        delete _owners[tokenId];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _mint(to, tokenId);

        require(_checkOnERC721Received(msg.sender, to, tokenId), "");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_exists(tokenId), "ERC721: token already minted");

        _owners[tokenId] = to;
        _balances[to]++;
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) {
            revert NotAnOwner(from, to, tokenId);
        }
        if (to == address(0)) {
            revert InvalidAddress(to);
        }

        _beforeTokenTransfer(from, to, tokenId);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _transfer(from, to, tokenId);

        if (!_checkOnERC721Received(from, to, tokenId)) {
            revert NonERC721Receiver(from, to, tokenId);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual returns (bool) {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual returns (bool) {}

    function tokenURI(
        uint256 tokenId
    ) external view override _requireMinted(tokenId) returns (string memory) {
        string memory _baseURIs = _baseURI(tokenId);
        return
            bytes(_baseURIs).length > 0
                ? string(abi.encode(_baseURIs, tokenId.toString()))
                : "";
    }

    function name() external view override returns (string memory) {
        return s_name;
    }

    function symbol() external view returns (string memory) {
        return s_symbol;
    }

    /// can operator manage all tokens of owner
    function isApprovedForAll(
        address owner,
        address operator
    ) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function ownerOf(
        uint256 _tokenId
    ) public view override _requireMinted(_tokenId) returns (address) {
        return _owners[_tokenId];
    }

    function getApproved(
        uint256 tokenId
    ) public view override _requireMinted(tokenId) returns (address) {
        return _tokenApprovals[tokenId];
    }

    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _owners[_tokenId] != address(0);
    }

    function _baseURI(
        uint256 /*_tokenId*/
    ) internal pure returns (string memory) {
        return "";
    }

    function _isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    ) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        return
            owner == _spender ||
            isApprovedForAll(owner, _spender) ||
            getApproved(_tokenId) == _spender;
    }

    // Checks if to is a smart contracts
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId
    ) private returns (bool) {
        if (to.code.length > 0) {
            // convert to in order to send
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    bytes("")
                )
            returns (bytes4 ret) {
                return ret == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert NonERC721Receiver(msg.sender, to, tokenId);
                } else {
                    assembly {
                        // Skip the first 32 bytes because of the memory allocation in solidity
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}
