// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract IrisOracle {

    struct Proposal {
        uint deadline;
        int latitude;
        int longitude;
        uint radius;
    }

    struct Reward {
        address recipient;
        uint256 amount;
        uint timestamp;
    }

    event ProposalInitiatedEvent (
      address proposer
    );

    event ProposalValidationEvent (
      address proposer,
      uint256 rewardId
    );

    address public owner;

    uint256 private rewardIdCounter;
    mapping(address => Proposal) private activeProposals;
    mapping(uint256 => Reward) private rewards;

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /*
     * Latitude and longitude are precise to 4 decimals (~11m) and represented as integers
     * (multiply by 0.0001 to convert back to original format). Radius is denoted
     * in meters, and the oracle monitors the circle centered at that point. Deadline
     * is the UNIX timestamp for when the proposal should be met by. Limit radius between 10
     * and 10,000 meters. Emit an event (oracle should listen for event off-chain).
     */
    function initiateProposal(uint deadline, int lat, int long, uint radius) public {
        require(activeProposals[msg.sender].deadline == 0, "Active proposal already exists.");
        require(deadline >= block.timestamp + 30 days, "Deadline must be at lease 30 days from now.");
        require(-900000 < lat && lat < 900000, "Invalid latitude.");
        require(-1800000 < long && long < 1800000, "Invalid longitude.");
        require(10 < radius && radius < 10000, "Radius must be between 10 and 10,000 meters.");

        activeProposals[msg.sender] = Proposal(deadline, lat, long, radius);
        emit ProposalInitiatedEvent(msg.sender);
    }

    /* Get an active proposal based on proposer address. */
    function getProposal(address proposer) public view returns (uint, int, int, uint) {
        require(activeProposals[proposer].deadline != 0, "Proposal does not exist.");

        Proposal memory p = activeProposals[proposer];
        return (p.deadline, p.latitude, p.longitude, p.radius);
    }

    /* Get reward data based on reward id. */
    function getReward(uint256 rewardId) public view returns (address, uint256, uint) {
        require(rewards[rewardId].timestamp != 0, "Reward does not exist.");

        Reward memory r = rewards[rewardId];
        return (r.recipient, r.amount, r.timestamp);
    }

    /* Called by owner (assume some satellite oracle) to validate the proposal and mint reward. */
    function validateProposal(address proposer, uint256 reward) public onlyOwner {
        require(activeProposals[proposer].deadline != 0, "Proposal does not exist.");
        delete activeProposals[proposer];

        uint256 rewardId = rewardIdCounter;
        rewardIdCounter += 1;

        rewards[rewardId] = Reward(proposer, reward, block.timestamp);
        emit ProposalValidationEvent(proposer, rewardIdCounter);
    }
}
