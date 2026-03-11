// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {CarbonTrade_001} from "../src/CarbonTrader_001.sol";
import {MockERC20} from "../test/MockERC20.sol";

contract DeployCarbonTrader is Script {
    function run() external {
        //从环境变量中读取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        //告诉foundry，接下来的操作，用我的签名部署到区块链上
        vm.startBroadcast(deployerPrivateKey);
        MockERC20 usdt = new MockERC20();
        console.log("USDT deployed at:", address(usdt));

        CarbonTrade_001 carbonTrade_001 = new CarbonTrade_001(address(usdt));
        console.log("CarbonTrade_001 deployed at:", address(carbonTrade_001));

        vm.stopBroadcast();
    }
}

