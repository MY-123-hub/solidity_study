import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import Wallet from './Wallet';
import { CARBON_TRADE_ADDRESS, USDT_ADDRESS } from './config';
import contractABI from './contractABI.json';
import './App.css';

const erc20ABI = [
  "function approve(address spender, uint256 amount) public returns (bool)"
];

// Helper function to truncate address
const truncateAddress = (address) => {
  if (!address) return "";
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
};

function App() {
  const [userAddress, setUserAddress] = useState('');
  const [signer, setSigner] = useState(null);
  const [usdtBalance, setUsdtBalance] = useState('');
  const [allowance, setAllowance] = useState('');
  const [depositAmount, setDepositAmount] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);

  // States for all functionalities
  const [tradeId, setTradeId] = useState('');
  const [tradeAmount, setTradeAmount] = useState('');
  const [tradePrice, setTradePrice] = useState('');
  const [tradeDuration, setTradeDuration] = useState('60');
  const [bidTradeId, setBidTradeId] = useState('');
  const [bidPrice, setBidPrice] = useState('');
  const [queryTradeId, setQueryTradeId] = useState('');
  const [tradeInfo, setTradeInfo] = useState(null);
  const [settleTradeId, setSettleTradeId] = useState('');
  const [withdrawAmount, setWithdrawAmount] = useState('');

  // All ethers.js logic remains unchanged...
  const fetchBalances = async () => {
    if (!signer) return;
    const contract = new ethers.Contract(CARBON_TRADE_ADDRESS, contractABI.abi, signer);
    try {
      const usdt = await contract.checkAvailableUSDT(userAddress);
      const carbonAllowance = await contract.checkAllowance(userAddress);
      setUsdtBalance(ethers.formatUnits(usdt, 18));
      setAllowance(carbonAllowance.toString());
    } catch (error) {
      console.error("Error fetching balances:", error);
    }
  };

  const handleApprove = async () => {
    if (!signer) return;
    setIsProcessing(true);
    try {
      const usdtContract = new ethers.Contract(USDT_ADDRESS, erc20ABI, signer);
      const tx = await usdtContract.approve(CARBON_TRADE_ADDRESS, ethers.MaxUint256);
      await tx.wait();
      alert("Approve Success!");
    } catch (error) {
      console.error("Approval failed:", error);
      alert("Approve Failed");
    } finally {
      setIsProcessing(false);
    }
  };

  const handleDeposit = async () => {
    if (!signer || !depositAmount) return;
    setIsProcessing(true);
    try {
      const platformContract = new ethers.Contract(CARBON_TRADE_ADDRESS, contractABI.abi, signer);
      const amount = ethers.parseUnits(depositAmount, 18);
      const tx = await platformContract.deposit(amount);
      await tx.wait();
      alert("Deposit Success!");
      setDepositAmount('');
      await fetchBalances();
    } catch (error) {
      console.error("Deposit failed:", error);
      alert("Deposit Failed");
    } finally {
      setIsProcessing(false);
    }
  };

  const handleStartTrade = async () => {
    if (!signer || !tradeId || !tradeAmount || !tradePrice || !tradeDuration) return;
    setIsProcessing(true);
    try {
      const contract = new ethers.Contract(CARBON_TRADE_ADDRESS, contractABI.abi, signer);
      const amount = BigInt(tradeAmount);
      const price = ethers.parseUnits(tradePrice, 18);
      const startTime = Math.floor(Date.now() / 1000);
      const endTime = startTime + parseInt(tradeDuration) * 60;
      const tx = await contract.startTrade(tradeId, amount, price, startTime, endTime);
      await tx.wait();
      alert("Trade Started!");
      setTradeId('');
      setTradeAmount('');
      setTradePrice('');
      setTradeDuration('60');
      await fetchBalances();
    } catch (error) {
      console.error("StartTrade failed:", error);
      alert("StartTrade Failed");
    } finally {
      setIsProcessing(false);
    }
  };

  const handleSetBid = async () => {
    if (!signer || !bidTradeId || !bidPrice) return;
    setIsProcessing(true);
    try {
      const contract = new ethers.Contract(CARBON_TRADE_ADDRESS, contractABI.abi, signer);
      const price = ethers.parseUnits(bidPrice, 18);
      const tx = await contract.setbid(bidTradeId, price);
      await tx.wait();
      alert("Bid Placed!");
      setBidTradeId('');
      setBidPrice('');
      await fetchBalances();
    } catch (error) {
      console.error("SetBid failed:", error);
      alert("SetBid Failed");
    } finally {
      setIsProcessing(false);
    }
  };

  const handleQueryTrade = async () => {
    if (!signer || !queryTradeId) return;
    setIsProcessing(true);
    try {
      const contract = new ethers.Contract(CARBON_TRADE_ADDRESS, contractABI.abi, signer);
      const info = await contract.getTradeInfo(queryTradeId);
      setTradeInfo({
        seller: info.seller,
        sellAmount: ethers.formatUnits(info.sellamount, 18),
        minPrice: ethers.formatUnits(info.minPrice, 18),
        status: info.status ? 'Active' : 'Closed/Settled',
        highestBidder: info.highestBidder,
        highestPrice: ethers.formatUnits(info.highestPrice, 18)
      });
    } catch (error) {
      console.error("QueryTrade failed:", error);
      alert("Query Failed");
      setTradeInfo(null);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleSettleTrade = async () => {
    if (!signer || !settleTradeId) return;
    setIsProcessing(true);
    try {
      const contract = new ethers.Contract(CARBON_TRADE_ADDRESS, contractABI.abi, signer);
      const tx = await contract.settleTrade(settleTradeId);
      await tx.wait();
      alert("Trade Settled!");
      setSettleTradeId('');
      await fetchBalances();
    } catch (error) {
      console.error("SettleTrade failed:", error);
      alert("Settle Failed");
    } finally {
      setIsProcessing(false);
    }
  };

  const handleWithdrawUSDT = async () => {
    if (!signer || !withdrawAmount) return;
    setIsProcessing(true);
    try {
      const contract = new ethers.Contract(CARBON_TRADE_ADDRESS, contractABI.abi, signer);
      const amount = ethers.parseUnits(withdrawAmount, 18);
      const tx = await contract.withdraw(amount);
      await tx.wait();
      alert("Withdraw USDT Success!");
      setWithdrawAmount('');
      await fetchBalances();
    } catch (error) {
      console.error("Withdraw USDT failed:", error);
      alert("Withdraw USDT Failed");
    } finally {
      setIsProcessing(false);
    }
  };

  const handleWithdrawAllowance = async () => {
    if (!signer || !withdrawAmount) return;
    setIsProcessing(true);
    try {
      const contract = new ethers.Contract(CARBON_TRADE_ADDRESS, contractABI.abi, signer);
      const amount = BigInt(withdrawAmount);
      const tx = await contract.unFreezeAllowance(userAddress, amount);
      await tx.wait();
      alert("Withdraw Allowance Success!");
      setWithdrawAmount('');
      await fetchBalances();
    } catch (error) {
      console.error("Withdraw Allowance failed:", error);
      alert("Withdraw Allowance Failed");
    } finally {
      setIsProcessing(false);
    }
  };

  useEffect(() => {
    if (userAddress) {
      fetchBalances();
    }
  }, [userAddress]);

  return (
    <div className="app-container">
      <h1 className="main-header">Carbon Trading Platform</h1>

      <div className="card">
        <h4>Wallet Connection</h4>
        <Wallet setAddress={setUserAddress} setSigner={setSigner} />
        {userAddress && <p style={{ marginTop: '1rem', color: 'var(--primary-accent)' }}>Connected: {truncateAddress(userAddress)}</p>}
      </div>

      {userAddress && (
        <div className="grid-layout">
          
          <div className="card balance-info">
            <h4>Account Balances</h4>
            <p><strong>Available USDT:</strong> <span>{usdtBalance || '0.0'}</span></p>
            <p><strong>Carbon Allowance:</strong> <span>{allowance || '0'}</span></p>
            <button className="btn-primary" onClick={fetchBalances} disabled={isProcessing}>Refresh</button>
          </div>

          <div className="card">
            <h4>Deposit USDT</h4>
            <input className="input-field" type="number" placeholder="Amount to deposit" value={depositAmount} onChange={(e) => setDepositAmount(e.target.value)} disabled={isProcessing} />
            <div className="button-group">
              <button className="btn-primary" onClick={handleApprove} disabled={isProcessing}>Approve</button>
              <button className="btn-primary" onClick={handleDeposit} disabled={isProcessing || !depositAmount}>Deposit</button>
            </div>
          </div>

          <div className="card">
            <h4>Start Trade</h4>
            <input className="input-field" type="text" placeholder="Trade ID" value={tradeId} onChange={(e) => setTradeId(e.target.value)} disabled={isProcessing} />
            <input className="input-field" type="number" placeholder="Amount to sell" value={tradeAmount} onChange={(e) => setTradeAmount(e.target.value)} disabled={isProcessing} />
            <input className="input-field" type="number" placeholder="Starting price" value={tradePrice} onChange={(e) => setTradePrice(e.target.value)} disabled={isProcessing} />
            <input className="input-field" type="number" placeholder="Duration (minutes)" value={tradeDuration} onChange={(e) => setTradeDuration(e.target.value)} disabled={isProcessing} />
            <button className="btn-primary" onClick={handleStartTrade} disabled={isProcessing || !tradeId || !tradeAmount || !tradePrice}>Initiate Auction</button>
          </div>

          <div className="card">
            <h4>Set Bid</h4>
            <input className="input-field" type="text" placeholder="Trade ID to bid on" value={bidTradeId} onChange={(e) => setBidTradeId(e.target.value)} disabled={isProcessing} />
            <input className="input-field" type="number" placeholder="Your bid price" value={bidPrice} onChange={(e) => setBidPrice(e.target.value)} disabled={isProcessing} />
            <button className="btn-primary" onClick={handleSetBid} disabled={isProcessing || !bidTradeId || !bidPrice}>Submit Bid</button>
          </div>

          <div className="card">
            <h4>Query Trade Info</h4>
            <input className="input-field" type="text" placeholder="Trade ID to query" value={queryTradeId} onChange={(e) => setQueryTradeId(e.target.value)} disabled={isProcessing} />
            <button className="btn-primary" onClick={handleQueryTrade} disabled={isProcessing || !queryTradeId}>Query</button>
            {tradeInfo && (
              <div className="trade-details">
                <p><strong>Seller:</strong> <span>{truncateAddress(tradeInfo.seller)}</span></p>
                <p><strong>Amount:</strong> <span>{tradeInfo.sellAmount}</span></p>
                <p><strong>Min Price:</strong> <span>{tradeInfo.minPrice}</span></p>
                <p><strong>Status:</strong> <span>{tradeInfo.status}</span></p>
                <p><strong>Highest Bidder:</strong> <span>{truncateAddress(tradeInfo.highestBidder)}</span></p>
                <p><strong>Highest Price:</strong> <span>{tradeInfo.highestPrice}</span></p>
              </div>
            )}
          </div>

          <div className="card">
            <h4>Settle Trade</h4>
            <input className="input-field" type="text" placeholder="Trade ID to settle" value={settleTradeId} onChange={(e) => setSettleTradeId(e.target.value)} disabled={isProcessing} />
            <button className="btn-primary" onClick={handleSettleTrade} disabled={isProcessing || !settleTradeId}>Settle</button>
          </div>

          <div className="card">
            <h4>Withdraw Assets</h4>
            <input className="input-field" type="number" placeholder="Amount to withdraw" value={withdrawAmount} onChange={(e) => setWithdrawAmount(e.target.value)} disabled={isProcessing} />
            <div className="button-group">
              <button className="btn-primary" onClick={handleWithdrawUSDT} disabled={isProcessing || !withdrawAmount}>Withdraw USDT</button>
              <button className="btn-primary" onClick={handleWithdrawAllowance} disabled={isProcessing || !withdrawAmount}>Withdraw Allowance</button>
            </div>
          </div>

        </div>
      )}
    </div>
  );
}

export default App;
