// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

contract CommunityFund {
  string public name;

  uint public requiredNbOfParticipants;
  uint public recurringAmount;
  uint public startDate;
  uint public duration;

  struct Participant {
    uint balance;
    bool collateral;
  }

  mapping (address => Participant) public participants;
  address[] public allParticipants;

  constructor(
    address _from,
    string memory _name,
    uint _requiredNbOfParticipants,
    uint _recurringAmount,
    uint _startDate,
    uint _duration
  ) payable {
    require(block.timestamp < _startDate, "start date of the fund must be in the future!");
    require((msg.value == 0) || (msg.value >= _recurringAmount * _duration * 120 / 100), "not enough collateral");

    name = _name;

    requiredNbOfParticipants = _requiredNbOfParticipants;
    recurringAmount          = _recurringAmount;
    duration                 = _duration;
    startDate                = _startDate;

    if (msg.value > 0) {
      participants[_from].balance   += msg.value;
      participants[_from].collateral = true;

      allParticipants.push(_from);
    }
  }

  function deposit() external payable {
    require(participants[msg.sender].collateral == true, "collateral required");
    require(msg.value == recurringAmount, "please deposit exact amount");

    // -- TODO: only allow for one deposit per month.
  
    participants[msg.sender].balance += msg.value;
  }

  function collateral() external payable {
    require(block.timestamp < startDate, "collateral must be committed before the funds starts");
    require(allParticipants.length < requiredNbOfParticipants, "max participants reached");
    require(participants[msg.sender].collateral == false, "collateral already locked");
    require(msg.value >= recurringAmount * duration * 120 / 100, "minimum collateral required");

    participants[msg.sender].balance   += msg.value;
    participants[msg.sender].collateral = true;

    allParticipants.push(msg.sender);
  }

  function withdraw() public {
    require(participants[msg.sender].collateral == true, "no committed collateral, nothing to withdraw");
    require(block.timestamp > startDate + 24 * 3600, "cannot withdraw before the fund starts");
    // -- TODO: add more conditions for when withdrawals are allowed
    // --       eg. cannot withdraw until the funds end date once the fund has started
    // --       and withdrawals allowed if the fund was not able to start (ie. not enough participants)

    uint amount = participants[msg.sender].balance;

    participants[msg.sender].balance    = 0;
    participants[msg.sender].collateral = false;

    payable(msg.sender).transfer(amount);
  }

  function getAllParticipants() external view returns (address[] memory) {
    return allParticipants;
  }
}
