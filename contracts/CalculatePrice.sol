//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@pangolindex/exchange-contracts/contracts/pangolin-core/interfaces/IPangolinPair.sol";
import "@pangolindex/exchange-contracts/contracts/pangolin-core/interfaces/IPangolinFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/Math.sol";
import "./libraries/SafeMath.sol";

contract CalculatePrice {
    using SafeMath for uint256;

    address public avax;
    address public usdc;
    address public factory;
    uint256 public baseUsdPrice;

    constructor(
        address _avax,
        address _usdc,
        address _factory,
        uint256 _baseUsdPrice
    ) {
        avax = _avax;
        usdc = _usdc;
        factory = _factory;
        baseUsdPrice = _baseUsdPrice;
    }

    function getPairAddress(address token1, address token2)
        public
        view
        returns (address)
    {
        address pair = IPangolinFactory(factory).getPair(token1, token2);
        return pair;
    }

    function getWolfiPriceInAvax()
        public
        view
        returns (uint256 wolfiPriceAvax)
    {
        address avaxUsdc = getPairAddress(avax, usdc);
        uint256 balanceAvax = IERC20(avax).balanceOf(avaxUsdc);
        uint256 balanceUsdc = IERC20(usdc).balanceOf(avaxUsdc);

        wolfiPriceAvax =
            (baseUsdPrice * balanceAvax * 1000000000000000000) /
            (balanceUsdc * 1000000000000);

        return wolfiPriceAvax;
    }
}
