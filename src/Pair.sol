// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "library/SafeMath.sol";
import "src/LPtoken.sol";

contract Pair is LPtoken("LPtoken", "LP", 18) {
    using SafeMath  for uint;

    uint256 public priceToken0 ;
    uint256 public priceToken1;
    uint256 public kLast;
    uint public reserve0;          
    uint public reserve1;  

    address token0;
    address token1;
    address factory;
    uint public constant MINIMUM_LIQUIDITY = 10**3;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    event Swap(address indexed to, uint256 amount0, uint256 amount1);
    event Mint(address indexed to, uint256 LPamount);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    constructor()  {
        factory = msg.sender;
    }

    function initialize(address _token0, address _token1) public {
        require(msg.sender == factory, 'Pair: FORBIDDEN'); // sufficient check
        (token0,token1) = sortTokens(_token0, _token1);
    }

    function getReserves() public view returns (uint _reserve0, uint _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address _token0, address _token1) {
        require(tokenA != tokenB, 'Pair: IDENTICAL_ADDRESSES');
        (_token0, _token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(_token0 != address(0), 'Pair: ZERO_ADDRESS');
    }

    function update(uint amount0, uint amount1) internal {
        if(amount0 != 0 && amount1 != 0){
            priceToken0 = amount1/amount0;
            priceToken1 = amount0/amount1;
        }
        reserve0 = amount0;
        reserve1 = amount1;
    }

    ///@dev internal function used to do the main swap
    ///@param  amount0Out is the amount of tokens in token0 to be given to the user
    ///@param  amount1Out is the amount of tokens in token1 to be given to the user
    ///@param to address to transfer tokens to
    function swap(uint256 amount0Out, uint256 amount1Out, address to) internal {
        require(amount0Out > 0 || amount1Out > 0, 'Pair: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint256  _token0, uint256 _token1)=getReserves();
        require(_token0 > amount0Out&& _token1 >amount1Out, "Pair: INSUFFICIENT FUNDS" );
        require(to != token0 && to != token1, 'Pair: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);
        uint256 balance0 = IERC202(token0).balanceOf(address(this));
        uint256 balance1 = IERC202(token1).balanceOf(address(this));

        update(balance0,balance1 );
        emit Swap(to, amount0Out, amount1Out);
    }

    ///@dev mint function is called by the router when a user provides liquidty 
    ///@param to the address to mint the LP tokens to
    function mint(address to) public  returns (uint liquidity) {
        (uint _reserve0, uint _reserve1) = getReserves(); // gas savings
        uint balance0 = IERC202(token0).balanceOf(address(this));
        uint balance1 = IERC202(token1).balanceOf(address(this));
        // the tokens that the LP povided is spend by the router to the Pair contract 
        // and the present balance is subtracted from the previous to get what the LP sent to the Pool
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        uint _totalSupply = totalSupply; // gas savings
        // checks to prevent multipling by 0
        if (_totalSupply == 0) {
            liquidity = SafeMath.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = SafeMath.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        update(balance0, balance1);
        kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, liquidity);
    }


    ///@dev burn is called by the router to remove liquidity
    ///@param to the address to sent the tokens the 
    function burn(address to) public  returns (uint amount0, uint amount1) {
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC202(_token0).balanceOf(address(this));
        uint balance1 = IERC202(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'Pair: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC202(_token0).balanceOf(address(this));
        balance1 = IERC202(_token1).balanceOf(address(this));

        update(balance0, balance1);
        kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

                /////////////////////////////////////////////////////PRIVATE FUNCTIONS/////////////////////////////////////////////
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }
}


interface IERC202{
    function balanceOf(address owner) external view returns (uint);
    function mint(address to, uint256 amount) external;
    function _burn(address from, uint256 amount) external;
}
