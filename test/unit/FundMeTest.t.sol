// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    enum Currency {
        ETH,
        SepoliaETH,
        APE
    }

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMesssageSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        if (block.chainid == 1 || block.chainid == 31337) {
            // Ethereum mainnet or Anvil
            vm.expectRevert();
            fundMe.fund{value: 0}(FundMe.Currency.ETH, 0);
        } else {
            revert("This test should only run on Ethereum mainnet or Anvil.");
        }
    }

    function testFundFailsWithoutEnoughSepoliaETH() public {
        if (block.chainid == 11155111) {
            vm.expectRevert();
            fundMe.fund{value: 0}(FundMe.Currency.SepoliaETH, 0);
        } else {
            revert("This test should only run on Sepolia testnet.");
        }
    }

    function testFundFailsWithoutEnoughAPE() public {
        if (block.chainid == 33111) {
            vm.expectRevert();
            fundMe.fund{value: 0}(FundMe.Currency.APE, 0);
        } else {
            revert("This test should only run on Curtis testnet.");
        }
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //the next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}(FundMe.Currency.ETH, 0);

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}(FundMe.Currency.ETH, 0);

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}(FundMe.Currency.ETH, 0);
        _;
    }

    function testNonOwnerCannootWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        assertEq(address(fundMe).balance, 0);
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal  - new money

            hoax(address(i), SEND_VALUE);

            // fund the fundMe
            fundMe.fund{value: SEND_VALUE}(FundMe.Currency.ETH, 0);
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assert(endingFundMeBalance == 0);
        assert(
            startingOwnerBalance + startingFundMeBalance == endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal  - new money

            hoax(address(i), SEND_VALUE);

            // fund the fundMe
            fundMe.fund{value: SEND_VALUE}(FundMe.Currency.ETH, 0);
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assert(endingFundMeBalance == 0);
        assert(
            startingOwnerBalance + startingFundMeBalance == endingOwnerBalance
        );
    }
}
