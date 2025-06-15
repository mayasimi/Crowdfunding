// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error GoalNotReached();
error GoalAlreadyReached();
error DeadlinePassed();
error NotOwner();
error WithdrawNotAllowed();
error AlreadyWithdrawn();

contract Crowdfunding {
    address public owner;
    uint256 public goal;
    uint256 public deadline;
    uint256 public totalFunds;
    bool public ownerWithdrawn;

    mapping(address => uint256) public contributions;
    mapping(address => bool) public refunded;

    event ContributionMade(address indexed contributor, uint256 amount);
    event OwnerWithdrawn(uint256 amount);
    event ContributorRefunded(address indexed contributor, uint256 amount);

    constructor(uint256 _goal, uint256 _durationInSeconds) {
        owner = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _durationInSeconds;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier beforeDeadline() {
        if (block.timestamp > deadline) revert DeadlinePassed();
        _;
    }

    function contribute() external payable beforeDeadline {
        require(msg.value > 0, "Contribution must be > 0");

        contributions[msg.sender] += msg.value;
        totalFunds += msg.value;

        emit ContributionMade(msg.sender, msg.value);
    }

    function withdrawFunds() external onlyOwner {
        if (block.timestamp < deadline && totalFunds < goal) {
            revert GoalNotReached();
        }

        if (totalFunds < goal) revert GoalNotReached();
        if (ownerWithdrawn) revert AlreadyWithdrawn();

        ownerWithdrawn = true;
        payable(owner).transfer(totalFunds);

        emit OwnerWithdrawn(totalFunds);
    }

    function refund() external {
        if (block.timestamp < deadline) revert WithdrawNotAllowed();
        if (totalFunds >= goal) revert GoalAlreadyReached();

        uint256 amount = contributions[msg.sender];
        require(amount > 0, "No funds to refund");
        require(!refunded[msg.sender], "Already refunded");

        refunded[msg.sender] = true;
        payable(msg.sender).transfer(amount);

        emit ContributorRefunded(msg.sender, amount);
    }

    function getTimeLeft() external view returns (uint256) {
        if (block.timestamp >= deadline) return 0;
        return deadline - block.timestamp;
    }

    function getStatus() external view returns (string memory) {
        if (totalFunds >= goal) return "Goal Reached";
        if (block.timestamp > deadline) return "Campaign Failed";
        return "In Progress";
    }
}
