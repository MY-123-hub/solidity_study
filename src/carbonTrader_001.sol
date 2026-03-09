// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import{IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error CarbonTrade_001_NotOwner();
error CarbonTrade_001_ParamsInvalid();
error CarbonTrade_001_TransferFailed();
error CarbonTrade_001_NotSeller();
error CarbonTrade_001_NoDeposit();
error CarbonTrade_001_TradeClosed();
error CarbonTrade_001_InsufficientBalance();
error CarbonTrade_001_TradeNotEnded();

contract CarbonTrade_001 {

    address public owner;
    IERC20 public usdtToken;

    mapping(address => uint256) public Allowance;
    mapping(address => uint256) public frozenAllowance;
    mapping(string => trade) public trades; // 订单ID => 订单详情
    mapping(address => string[]) public userTrades; // 用户地址 => 订单ID列表
    mapping(address => uint256) public availableUSDT; // 用户地址 => 可用USDT余额
    mapping(address => uint256) public frozenUSDT; // 用户地址 => 冻结USDT余额

    // 交易订单结构体
    struct trade {
        string tradeID;     //交易ID
        address seller;     //卖家地址
        uint256 sellamount; //卖出数量
        uint256 minPrice;   //最低价格
        uint256 starttime;  //开始时间
        uint256 endtime;    //结束时间
        bool status;        //订单状态
        address highestBidder; //最高出价者
        uint256 highestPrice;  //最高价格
        mapping(address => uint256) bidPrices; // 每个用户的竞价金额
    }

   modifier onlyOwner() {
        if(msg.sender != owner){
            revert CarbonTrade_001_NotOwner();
        }
        _;
    }

    constructor(address _usdtAddress) {
        owner = msg.sender;
        usdtToken = IERC20(_usdtAddress);
    }


    //usdt相关操作
    function deposit(uint256 _amount) public {
        if(_amount <= 0){
            revert CarbonTrade_001_ParamsInvalid();
        }
        if(usdtToken.transferFrom(msg.sender, address(this), _amount) == false){
            revert CarbonTrade_001_TransferFailed();
        }
        availableUSDT[msg.sender] += _amount;
    }
    //withdraw usdt
    function withdraw(uint256 _amount) public {
        if(_amount <= 0){
            revert CarbonTrade_001_ParamsInvalid();
        }
        if(availableUSDT[msg.sender] < _amount){
            revert CarbonTrade_001_InsufficientBalance();
        }
        
        availableUSDT[msg.sender] -= _amount;
        
        if(usdtToken.transfer(msg.sender, _amount) == false){
            revert CarbonTrade_001_TransferFailed();
        }
    }

    function withdrawAll() public {
        uint256 amount = availableUSDT[msg.sender];
        if(amount == 0){
            revert CarbonTrade_001_InsufficientBalance();
        }
        withdraw(amount);
    }

    function checkAvailableUSDT(address _addr) public view returns (uint256) {
        return availableUSDT[_addr];
    }
    // 内部冻结逻辑（由合约内部调用）
    function _freezeUSDT(address _addr, uint256 _amount) internal {
        availableUSDT[_addr] -= _amount;
        frozenUSDT[_addr] += _amount;
    }
    // 内部解冻逻辑
    function _unFreezeUSDT(address _addr, uint256 _amount) internal {
        frozenUSDT[_addr] -= _amount;
        availableUSDT[_addr] += _amount;
    }

    // admin专属手动解冻（用于特殊情况处理）
    function adminUnFreezeUSDT(address _addr, uint256 _amount)  onlyOwner public {
        _unFreezeUSDT(_addr, _amount);
    }

    //查询用户冻结usdt余额
    function checkfrozenUSDT(address _addr) public view returns (uint256) {
        return frozenUSDT[_addr];
    }


    //admin专属
    

    function issueAllowance(address _addr, uint256 _amount)  onlyOwner public {
        Allowance[_addr] += _amount;
    }
    function freezeAllowance(address _addr, uint256 _amount)  onlyOwner public {
        frozenAllowance[_addr] += _amount;
        Allowance[_addr] -= _amount;
    }
    
    function unFreezeAllowance(address _addr, uint256 _amount)  onlyOwner public {
        frozenAllowance[_addr] -= _amount;
        Allowance[_addr] += _amount;
    }
    

    //查询用户allowance余额
    function checkAllowance(address _addr) public view returns (uint256) {
        return Allowance[_addr];
    }
    //查询用户冻结allowance余额
    function checkFreezeAllowance(address _addr) public view returns (uint256) {
        return frozenAllowance[_addr];
    }
    //查询用户订单状态
    function checkStatus(string memory _tradeID) public view returns (bool) {
        return trades[_tradeID].status;
    }
    
    
    // seller专属
    function startTrade(
        string memory _tradeID,
        uint256 _sellamount,
        uint256 _minPrice,
        uint256 _starttime,
        uint256 _endtime
    ) public {
        if(_sellamount <= 0 || _minPrice == 0 || _starttime >= _endtime){
            revert CarbonTrade_001_ParamsInvalid();
        }
        if(trades[_tradeID].seller != address(0)){
            revert CarbonTrade_001_ParamsInvalid(); // 订单ID已存在
        }
        
        trade storage order = trades[_tradeID];
        order.tradeID = _tradeID;
        order.seller = msg.sender;
        order.sellamount = _sellamount;
        order.minPrice = _minPrice;
        order.starttime = _starttime;
        order.endtime = _endtime;
        order.status = true;
        
        userTrades[msg.sender].push(_tradeID);
        // 检查卖家是否有足够的allowance
        if(Allowance[msg.sender] < _sellamount){
            revert CarbonTrade_001_NoDeposit();
        }
        Allowance[msg.sender] -= _sellamount;
        frozenAllowance[msg.sender] += _sellamount;
    }

    //获取交易信息
    function getTradeInfo(string memory _tradeID) public view returns (
        address seller,
        uint256 sellamount,
        uint256 minPrice,
        uint256 starttime,
        uint256 endtime,
        bool status,
        address highestBidder,
        uint256 highestPrice
    ) {
        trade storage order = trades[_tradeID];
        return (
            order.seller,
            order.sellamount,
            order.minPrice,
            order.starttime,
            order.endtime,
            order.status,
            order.highestBidder,
            order.highestPrice
        );
    }

    //存储竞价信息
    function setbid(string memory _tradeID, uint256 _price) public {
        trade storage order = trades[_tradeID];
        if(order.status == false){
            revert CarbonTrade_001_TradeClosed();
        }
        if(block.timestamp < order.starttime || block.timestamp > order.endtime){
            revert CarbonTrade_001_ParamsInvalid();
        }
        if(_price < order.minPrice || _price <= order.highestPrice){
            revert CarbonTrade_001_ParamsInvalid();
        }
        
        // 检查出价者是否有足够的USDT余额
        if(availableUSDT[msg.sender] < _price){
            revert CarbonTrade_001_InsufficientBalance();
        }

        // 1. 退还前一个最高出价者的冻结资金
        if(order.highestBidder != address(0)){
            _unFreezeUSDT(order.highestBidder, order.highestPrice);
        }

        // 2. 冻结当前出价者的资金
        _freezeUSDT(msg.sender, _price);

        // 3. 更新订单信息
        order.bidPrices[msg.sender] = _price;
        order.highestBidder = msg.sender;
        order.highestPrice = _price;
    }
    //查询竞价信息
    function getbid(string memory _tradeID, address _addr) public view returns (uint256) {
        return trades[_tradeID].bidPrices[_addr];
    }

    //结算函数
    function settleTrade(string memory _tradeID) public {
        trade storage order = trades[_tradeID];
        
        // 只有卖家或 owner 可以触发结算
        if(msg.sender != order.seller && msg.sender != owner){
            revert CarbonTrade_001_NotSeller();
        }
        
        // 检查订单是否已激活
        if(order.status == false){
            revert CarbonTrade_001_TradeClosed();
        }
        
        // 如果未过结束时间，只有管理员可以强制结算；或者没有出价者时卖家可以撤单
        if(block.timestamp <= order.endtime && msg.sender != owner && order.highestBidder != address(0)){
            revert CarbonTrade_001_TradeNotEnded();
        }

        order.status = false; // 关闭订单

        if(order.highestBidder != address(0)){
            // 有人竞价成功
            address winner = order.highestBidder;
            uint256 amount = order.sellamount;
            uint256 totalPrice = order.highestPrice;

            // 划转资金：从买家的冻结余额中扣除，增加到卖家的可用余额
            frozenUSDT[winner] -= totalPrice;
            availableUSDT[order.seller] += totalPrice;

            // 划转碳配额：从卖家的冻结余额中扣除，增加到买家的可用余额
            frozenAllowance[order.seller] -= amount;
            Allowance[winner] += amount;
        } else {
            // 无人竞价，直接退还卖家配额
            frozenAllowance[order.seller] -= order.sellamount;
            Allowance[order.seller] += order.sellamount;
        }
    }

    // 撤单/流标处理逻辑（如果需要显式退还资金给最后一位出价者）
    function cancelTrade(string memory _tradeID) public {
        trade storage order = trades[_tradeID];
        if(msg.sender != order.seller && msg.sender != owner){
            revert CarbonTrade_001_NotSeller();
        }
        if(order.status == false){
            revert CarbonTrade_001_TradeClosed();
        }

        order.status = false;
        
        // 退还最高出价者的冻结USDT
        if(order.highestBidder != address(0)){
            _unFreezeUSDT(order.highestBidder, order.highestPrice);
        }

        // 退还卖家的碳配额
        frozenAllowance[order.seller] -= order.sellamount;
        Allowance[order.seller] += order.sellamount;
    }
}


