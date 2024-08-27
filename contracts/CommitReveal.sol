// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CommitReveal is Ownable {
    address[] public s_candidates = [
        0x71905F1673D3ABB2Fd1866f6c321A78D6061ceF2,
        0xbb7C0df5421c0718437cFd83D05085a88b249365,
        0xA639F9afe84735ad366971943aDC56dEb0d5Ad89
    ];

    mapping(address => bytes32) public s_commits;
    mapping(address => uint256) public s_votes;
    bool internal s_votingStopped;

    constructor() Ownable(msg.sender) {}

    // Hash is obtained in front-end
    function commitVote(bytes32 _hashedVote) external {
        require(!s_votingStopped, "Voting stopped");
        require(s_commits[msg.sender] == bytes32(0), "Already voted");

        s_commits[msg.sender] = _hashedVote;
    }

    function stopVoting() external onlyOwner {
        require(!s_votingStopped);

        s_votingStopped = true;
    }

    function revealVote(
        address _candidate,
        bytes32 _secret
    ) external onlyOwner {
        require(s_votingStopped, "Voting stopped");
        bytes32 commit = keccak256(
            abi.encodePacked(_candidate, _secret, msg.sender)
        );

        require(commit == s_commits[msg.sender], "Wrong commit");

        delete s_commits[msg.sender];

        s_votes[_candidate]++;
    }
}

// ethers.solidityPackedKeccak256(['address','bytes32','address'],[])
// ethers.encodeBytes32String
// secret

// 0x7365637265740000000000000000000000000000000000000000000000000000

//0x1d794c04981a5da712210758ab4044a325a3610c80b0c97fefc5effe84c66f11
