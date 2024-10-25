// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    //State Variables!
    address private immutable i_owner;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    enum Currency {
        ETH,
        SepoliaETH,
        APE
    }

    IERC20 public constant apeToken =
        IERC20(0x6Cb8Cc1e323357Af5da49d90FCb7160B7f09e6Cd);

    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;

    constructor(address pricefeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(pricefeed);
    }

    //Fund with ETH, SepoliaETH, or APE
    function fund(Currency currency, uint256 apeAmount) public payable {
        if (currency == Currency.ETH) {
            require(
                block.chainid == 1 || block.chainid == 31337,
                "Not on Ethereum mainnet or Anvil"
            );
            require(
                msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
                "You need to spend more ETH!"
            );

            // Handle the received ETH
            s_addressToAmountFunded[msg.sender] += msg.value;
            s_funders.push(msg.sender);
        } else if (currency == Currency.SepoliaETH) {
            require(block.chainid == 11155111, "Not on Sepolia testnet");
            require(
                msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
                "You need to spend more SepoliaETH!"
            );

            // Handle the received SepoliaETH
            s_addressToAmountFunded[msg.sender] += msg.value;
            s_funders.push(msg.sender);
        } else if (currency == Currency.APE) {
            require(apeAmount > 0, "You need to specify APE amount!");

            // Handle the received APE tokens
            bool success = apeToken.transferFrom(
                msg.sender,
                address(this),
                apeAmount
            );
            require(success, "APE Transfer failed");
        } else {
            revert("Unsupported currency type");
        }
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        // Treat as funding with SepoliaETH or ETH based on the chain
        if (block.chainid == 1 || block.chainid == 31337) {
            fund(Currency.ETH, 0); // Ethereum mainnet or Anvil local blockchain
        } else if (block.chainid == 11155111) {
            fund(Currency.SepoliaETH, 0); // Sepolia testnet ETH
        } else {
            revert("Unsupported network");
        }
    }

    receive() external payable {
        // Treat as funding with SepoliaETH or ETH based on the chain
        if (block.chainid == 1 || block.chainid == 31337) {
            fund(Currency.ETH, 0); // Ethereum mainnet or Anvil local blockchain
        } else if (block.chainid == 11155111) {
            fund(Currency.SepoliaETH, 0); // Sepolia testnet ETH
        } else {
            revert("Unsupported network");
        }
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    function withdraw() public onlyOwner {
        // Delete Funder Amount Funded
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        // Withdraw all ETH
        payable(i_owner).transfer(address(this).balance);

        // Withdraw all APE
        uint256 apeBalance = apeToken.balanceOf(address(this));
        if (apeBalance > 0) {
            apeToken.transfer(i_owner, apeBalance);
        }
    }

    // Not set up for APE
    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    /*
     *View / Pure functions (Getters)
     */

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly
