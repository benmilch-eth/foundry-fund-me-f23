// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../src/PriceConverter.sol"; // Adjust path as necessary
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract PriceConverterTest is Test {
    using PriceConverter for uint256;

    AggregatorV3Interface internal priceFeed;

    function setUp() public {
        // Initialize the priceFeed with the Sepolia ETH/USD address
        priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
    }

    function testGetPrice() public view {
        uint256 price = PriceConverter.getPrice(priceFeed);
        console.log("ETH Price in USD:", price / 1e8); // Price should be in the standard 8 decimal format
        assertGt(price, 0);
    }

    function testGetConversionRate() public view {
        uint256 ethAmount = 1e18; // 1 ETH in Wei
        uint256 usdAmount = PriceConverter.getConversionRate(
            ethAmount,
            priceFeed
        );
        console.log("Conversion Rate of 1 ETH in USD:", usdAmount);
        assertGt(usdAmount, 0);

        // Check how much ETH you need to reach $5
        uint256 minimumUsd = 5 * 1e18; // $5 in Wei (standardized to 18 decimals)
        uint256 ethRequired = minimumUsd / PriceConverter.getPrice(priceFeed);
        console.log("Minimum ETH Required for $5:", ethRequired);
    }
}
