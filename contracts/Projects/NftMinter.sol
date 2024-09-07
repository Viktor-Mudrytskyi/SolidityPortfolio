// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NftMinter is ERC721 {
    using Strings for uint256;
    string public constant COLLECTION_NAME = "NFT Minter";
    string public constant COLLECTION_SYMBOL = "NFTM";
    uint256 public constant MIN_PRICE = 1 ether;
    IERC20 public immutable token;

    uint256 private _nextTokenId;

    constructor(address _token) ERC721(COLLECTION_NAME, COLLECTION_SYMBOL) {
        token = IERC20(_token);
    }

    function mintWithToken(address _to, uint256 _amount) public {
        require(_to != address(0), "Zero address");
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Not enough allowance"
        );
        require(_amount >= MIN_PRICE, "Invalid amount");
        token.transferFrom(msg.sender, _to, _amount);
        _safeMint(_to, _nextTokenId);
        _nextTokenId++;
    }

    function getAllownace(address _sender) public view returns (uint256) {
        return token.allowance(_sender, address(this));
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://customdomain.com/";
    }
}
