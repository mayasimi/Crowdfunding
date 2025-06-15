// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


import "forge-std/Test.sol";
import { Crowdfunding} from "..src/Crowdfunding .sol";

contract CrowdfundingTest is Test {
    Crowdfunding crowdfunding;
    address owner = address(1);
    address user1 = address(2);
    address user2 = address(3);

    uint goal = 5 ether;
    uint duration = 5 days;

    function setUp() public {
        vm.prank(owner);
        crowdfunding = new Crowdfunding(goal, duration);
    }

    function testContributeIncreasesBalance() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        crowdfunding.contribute{value: 1 ether}();

        assertEq(crowdfunding.contributions(user1), 1 ether);
        assertEq(address(crowdfunding).balance, 1 ether);
    }

    function testFailZeroContribution() public {
        vm.prank(user1);
        crowdfunding.contribute{value: 0 ether}(); // should revert
    }

    function testWithdrawByOwnerAfterGoalMet() public {
        vm.deal(user1, 3 ether);
        vm.deal(user2, 2 ether);

        vm.prank(user1);
        crowdfunding.contribute{value: 3 ether}();

        vm.prank(user2);
        crowdfunding.contribute{value: 2 ether}();

        skip(duration + 1); // simulate deadline passed

        uint balanceBefore = owner.balance;
        vm.prank(owner);
        crowdfunding.withdrawByOwner();
        assertGt(owner.balance, balanceBefore);
    }

    function testWithdrawByContributorIfGoalNotMet() public {
        vm.deal(user1, 2 ether);
        vm.prank(user1);
        crowdfunding.contribute{value: 2 ether}();

        skip(duration + 1); // simulate deadline passed

        uint userBalanceBefore = user1.balance;
        vm.prank(user1);
        crowdfunding.withdrawByContributor();

        assertGt(user1.balance, userBalanceBefore);
        assertEq(crowdfunding.contributions(user1), 0);
    }

    function testFailWithdrawByOwnerBeforeDeadline() public {
        vm.deal(user1, 5 ether);
        vm.prank(user1);
        crowdfunding.contribute{value: 5 ether}();

        vm.prank(owner);
        crowdfunding.withdrawByOwner(); // should revert because deadline not reached
    }

    function testFailWithdrawIfAlreadyDone() public {
        vm.deal(user1, 3 ether);
        vm.deal(user2, 2 ether);

        vm.prank(user1);
        crowdfunding.contribute{value: 3 ether}();

        vm.prank(user2);
        crowdfunding.contribute{value: 2 ether}();

        skip(duration + 1);

        vm.prank(owner);
        crowdfunding.withdrawByOwner();

        vm.prank(owner);
        crowdfunding.withdrawByOwner(); // should revert (already withdrawn)
    }
}
