// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "library/MiniLibrary.sol";
import "solidity-lib/libraries/TransferHelper.sol";

contract Router {
    address immutable factory;

    constructor(address _factory){
        factory = _factory;
    }

    function addliquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        address to,
        uint amountAMin,
        uint amountBMin) public returns(uint amountA, uint amountB, uint liquidity){
        if (MiniLibrary.pairFor(factory,tokenA, tokenB) == address(0)) {
            IMini(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = MiniLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = MiniLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = MiniLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
        address pair = MiniLibrary.pairFor(factory, tokenA, tokenB);

        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IPair(pair).mint(to);

    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to
    )public  returns (uint amountA, uint amountB) {
        address pair = MiniLibrary.pairFor(factory, tokenA, tokenB);
        IPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        /// when removing liquidity the following happens
        /// -first the tokens LP tokens are transferred into the contract
        /// -secondly when the burn function is called it gets the amount to tokens that should
        /// be transferred back to the LP
        (uint amount0, uint amount1) = IPair(pair).burn(to);
        (address token0,) = MiniLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'Router: INSUFFICIENT_B_AMOUNT');
    }

        function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = MiniLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? MiniLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IPair(MiniLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external  returns (uint[] memory amounts) {
        amounts = MiniLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, MiniLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to
    ) external  returns (uint[] memory amounts) {
        amounts = MiniLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, MiniLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
}

interface IMini{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPair{
    function mint(address to) external  returns (uint liquidity);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function burn(address from) external returns(uint amount0, uint amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to) external;
}
