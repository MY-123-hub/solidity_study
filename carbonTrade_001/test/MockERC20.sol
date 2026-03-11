// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockUSDT", "USDT") {
    }

    //允许任何人铸造代币，方便测试
    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
