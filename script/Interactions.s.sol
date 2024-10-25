//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Fund
contract FundFundMe is Script {
    uint256 constant SEND_VALUE_APE = 1 * 10 ** 18; // 1 APE tokens
    uint256 constant SEND_VALUE = 1 ether;
    address USER = makeAddr("user");

    function fundFundMeWithETH(address mostRecentlyDeployed) public {
        // vm.prank(USER); // only for integration test
        // Use Currency.ETH (enum value 0) and pass 0 for apeAmount since we're sending ETH
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}(
            FundMe.Currency.ETH,
            0
        );
        console.log("Funded FundMe with %s ETH", SEND_VALUE / 1 ether);
    }

    function fundFundMeWithAPE(address mostRecentlyDeployed) public {
        //    vm.prank(USER); // only for integration test
        // Use Currency.APE (enum value 2) and specify the amount of APE tokens
        FundMe(payable(mostRecentlyDeployed)).fund(
            FundMe.Currency.APE,
            SEND_VALUE_APE
        );
        console.log("Funded with %s APE", SEND_VALUE_APE / 10 ** 18);
    }

    function fundFundMeWithSepoliaETH(address mostRecentlyDeployed) public {
        //    vm.prank(USER); // only for integration test
        // Use Currency.SepoliaETH (enum value 1) and pass 0 for apeAmount since we're sending SepoliaETH
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}(
            FundMe.Currency.SepoliaETH,
            0
        );
        console.log("Funded FundMe with %s SepoliaETH", SEND_VALUE / 1 ether);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        vm.startBroadcast();
        // Check which chain you're on and call the appropriate funding function
        if (block.chainid == 1 || block.chainid == 31337) {
            // Ethereum mainnet or Anvil
            fundFundMeWithETH(mostRecentlyDeployed);
        } else if (block.chainid == 11155111) {
            // Sepolia testnet
            fundFundMeWithSepoliaETH(mostRecentlyDeployed);
        } else if (block.chainid == 33111) {
            // Curtis testnet
            fundFundMeWithAPE(mostRecentlyDeployed);
        } else {
            revert(
                "Must use ETH mainnet, Sepolia testnet, Curtis testnet, or Anvil"
            );
        }
        vm.stopBroadcast();
    }
}

// Withdraw
contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        //    vm.prank(FundMe(payable(mostRecentlyDeployed)).getOwner()); //only for Integration test
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        console.log("Withdraw FundMe balance!");
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        vm.startBroadcast();
        withdrawFundMe(mostRecentlyDeployed);
        vm.stopBroadcast();
    }
}
