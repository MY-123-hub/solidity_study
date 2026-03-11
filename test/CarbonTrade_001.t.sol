// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {CarbonTrade_001} from "../src/CarbonTrader_001.sol";
import {MockERC20} from "./MockERC20.sol";

contract CarbonTrade_001_Test is Test{
    CarbonTrade_001 public carbonTrade_001;
    MockERC20 public usdt;


    //整几个用户来做测试
    address public admin = address(0x01);
    address public seller = address(0x02);
    address public buyer1 = address(0x03);
    address public buyer2 = address(0x04);

     // 初始化测试环境 每次跑测试前都会先执行setUp的代码
    function setUp() public {
        //部署假usdt
        usdt = new MockERC20();
        //以管理员身份部署碳交易合约
        vm.startPrank(admin);
        carbonTrade_001 = new CarbonTrade_001(address(usdt));
        vm.stopPrank();
        // 给管理员和卖家各分配1000个USDT
        usdt.mint(admin, 1000 * 10**6);
        usdt.mint(seller, 1000 * 10**6);
        //用管理员身份给卖家整100个碳配额
        vm.prank(admin);
        carbonTrade_001.issueAllowance(seller, 100);
        // 给买家1和买家2各分配1000个USDT
        usdt.mint(buyer1, 1000 * 10**6);
        usdt.mint(buyer2, 1000 * 10**6);
        console.log("USDT Address:", address(usdt));
        console.log("CarbonTrade Address:", address(carbonTrade_001));
    }

    //测试卖家能不能发起拍卖
    function testSellerCanCreateTrade() public {
        // 卖家发起拍卖
        vm.startPrank(seller);
        carbonTrade_001.startTrade(
            "trade1",
            50,                      // 碳配额
            100 * 10**6,
            block.timestamp + 1000,
            block.timestamp + 2000
        );
        vm.stopPrank();

        // 断言
        ( , , uint256 sellamount, , , , bool status, , ) = carbonTrade_001.trades("trade1");
        assertEq(sellamount, 50);
        assertEq(status, true);
    }

    // 测试充值与竞价流程
    function testDepositAndBid() public {
        uint256 bidAmount = 150 * 10**6;

        // 1. 卖家先发起拍卖
        vm.prank(seller);
        carbonTrade_001.startTrade("trade1", 50, 100 * 10**6, block.timestamp + 1, block.timestamp + 1000);

        // 2. 买家1充值 USDT
        vm.startPrank(buyer1);
        usdt.approve(address(carbonTrade_001), bidAmount);
        carbonTrade_001.deposit(bidAmount);
        
        // 3. 模拟时间到达拍卖开始
        vm.warp(block.timestamp + 10);
        
        // 4. 买家1进行竞价
        carbonTrade_001.setbid("trade1", bidAmount);
        vm.stopPrank();

        // 断言竞价成功
        ( , , , , , , , address highestBidder, uint256 highestPrice) = carbonTrade_001.trades("trade1");
        assertEq(highestBidder, buyer1);
        assertEq(highestPrice, bidAmount);
        assertEq(carbonTrade_001.frozenUSDT(buyer1), bidAmount);
        assertEq(carbonTrade_001.availableUSDT(buyer1), 0);
    }

    // 测试结算流程
    function testSettleTrade() public {
        uint256 bidAmount = 150 * 10**6;
        
        // 1. 卖家发起拍卖
        vm.prank(seller);
        carbonTrade_001.startTrade("trade1", 50, 100 * 10**6, block.timestamp + 1, block.timestamp + 1000);

        // 2. 买家1充值并竞价
        vm.startPrank(buyer1);
        usdt.approve(address(carbonTrade_001), bidAmount);
        carbonTrade_001.deposit(bidAmount);
        vm.warp(block.timestamp + 10);
        carbonTrade_001.setbid("trade1", bidAmount);
        vm.stopPrank();

        // 3. 模拟时间到达拍卖结束
        vm.warp(block.timestamp + 2000);

        // 4. 管理员结算
        vm.prank(admin);
        carbonTrade_001.settleTrade("trade1");

        // 5. 断言结算结果
        // 买家1获得碳配额
        assertEq(carbonTrade_001.Allowance(buyer1), 50);
        // 卖家获得 USDT 可用余额
        assertEq(carbonTrade_001.availableUSDT(seller), bidAmount);
        // 买家1冻结的 USDT 已扣除
        assertEq(carbonTrade_001.frozenUSDT(buyer1), 0);
        // 订单状态已关闭
        ( , , , , , , bool status, , ) = carbonTrade_001.trades("trade1");
        assertEq(status, false);
    }
}

