import { ethers } from 'ethers';

function Wallet({ setAddress, setSigner }) {
  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const address = await signer.getAddress();
        setAddress(address);
        setSigner(signer);
      } catch (error) {
        console.error("Failed to connect wallet:", error);
      }
    } else {
      alert('Please install MetaMask!');
    }
  };

  return (
    <button onClick={connectWallet}>Connect Wallet</button>
  );
}

export default Wallet;
