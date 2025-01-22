// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Voting {
  IERC20 public token;
  uint256 public votingDeadline;
  uint256 public votesFor;
  uint256 public votesAgainst;

  mapping(address => bool) public hasVoted;
  mapping(address => bool) public voteChoice;
  mapping(address => uint256) public voteWeight;

  event VoteCasted(address voter, bool vote, uint256 weight);
  event VotesRemoved(address voter, uint256 weight);

  constructor(address _tokenAddress, uint256 _votingPeriod) {
    token = IERC20(_tokenAddress);
    votingDeadline = block.timestamp + _votingPeriod;
  }

  function vote(
    bool _inFavor
  ) external {
    require(block.timestamp < votingDeadline, " Voting has ended ");
    require(!hasVoted[msg.sender], " Already voted ");

    uint256 balance = token.balanceOf(msg.sender);
    require(balance > 0, " No tokens to vote ");

    if (_inFavor) {
      votesFor += balance;
    } else {
      votesAgainst += balance;
    }

    hasVoted[msg.sender] = true;
    voteChoice[msg.sender] = _inFavor;
    voteWeight[msg.sender] = balance;

    emit VoteCasted(msg.sender, _inFavor, balance);
  }

  function removeVotes(
    address from
  ) external {
    require(
      msg.sender == address(token), " Only the token contract can remove votes "
    );

    if (hasVoted[from]) {
      uint256 weight = voteWeight[from];

      if (voteChoice[from]) {
        votesFor -= weight;
      } else {
        votesAgainst -= weight;
      }

      delete hasVoted[from];
      delete voteChoice[from];
      delete voteWeight[from];

      emit VotesRemoved(from, weight);
    }
  }

  function getResult() external view returns (bool) {
    require(block.timestamp >= votingDeadline, " Voting is not over ");
    return votesFor > votesAgainst;
  }
}
