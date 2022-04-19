//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "hardhat/console.sol";

// EACAggregatorProxy is used for chainlink oracle
interface EACAggregatorProxy {
  function latestAnswer() external view returns (int256);
}

// Uniswap v3 interface
interface IUniswapRouter is ISwapRouter {
  function refundETH() external payable;
}

// Add deposit function for WETH
interface DepositableERC20 is IERC20 {
  function deposit() external payable;
}
/*
@title Vault
@notice A vault to automate trading strategy
*/
contract Vault {

    using SafeERC20 for IERC20;
    using SafeERC20 for DepositableERC20;

    uint public version = 1;

    /* Kovan Addresses */
    address public daiAddress = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    address public wethAddress = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address public uinswapV3QuoterAddress = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address public uinswapV3RouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public chainLinkETHUSDAddress = 0x9326BFA02ADD2366b30bacB125260Af641031331;

    uint public ethPrice = 0;
    uint public usdTargetPercentage = 40;
    uint public usdDividendPercentage = 25; // 25% of 40% = 10% Annual Drawdown
    uint private dividendFrequency = 3 minutes; // change to 1 years for production
    uint public nextDividendTS;
    address public owner;

    IERC20 daiToken = IERC20(daiAddress);
    DepositableERC20 wethToken = DepositableERC20(wethAddress);
    IQuoter quoter = IQuoter(uinswapV3QuoterAddress);
    IUniswapRouter uniswapRouter = IUniswapRouter (uinswapV3RouterAddress);

    event myVaultLog(string msg, uint ref);

constructor() {
    console.log("Deploying myVault Version:", version);
    nextDividendTS = block.timestamp + dividendFrequency;
    owner = msg.sender;
  }

  function getDaiBalance() public view returns (uint) { 
      return daiToken.balanceOf(address(this));
  }

  function getWethBalance() public view returns (uint) {
      return wethToken.balanceOf(address(this));
  }
  function getTotalBalance() public view returns (uint) {
      require(ethPrice > 0, "ETH price has not been set");
      uint daiBalance = getDaiBalance();
      uint wethBalance = getWethBalance();
      uint wethUSD = wethBalance * ethPrice; // assumes both assets have 18 decimals
      uint totalBalance = wethUSD + daiBalance;
      return totalBalance;
  }

  function updateEthPriceUniswap() public returns(uint) {
  uint ethPriceRaw = quoter.quoteExactOutputSingle(daiAddress,wethAddress,3000,100000,0);
  ethPrice = ethPriceRaw / 100000;
  return ethPrice;
}

function updateEthPriceChainlink() public returns(uint) {
  int256 chainLinkEthPrice = EACAggregatorProxy(chainLinkETHUSDAddress).latestAnswer();
  ethPrice = uint(chainLinkEthPrice / 100000000);
  return ethPrice;
}






}
