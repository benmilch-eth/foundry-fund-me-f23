// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        console.log("Contract owner", fundMe.getOwner());
    }

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();

        // Simulate USER calling the function to fund with 1 ether
        vm.deal(USER, STARTING_BALANCE);
        fundFundMe.fundFundMe(address(fundMe));

        //Log contract balance after funding to ensure it received the funds
        console.log("FundMe contract balance after funding:", address(fundMe).balance);
        assert(address(fundMe).balance == 1 ether); //Ensure contract has 1 ether

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        // After withdrawal, assert the contract balance is 0.
        assert(address(fundMe).balance == 0);

        //   address funder = fundMe.getFunder(0);
        //   assertEq(funder, USER);
    }
}
