// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PairFactory.sol";

import "../src/Router.sol";

// import "../src/Pair.sol";

import "../src/Metoken.sol";


contract CounterTest is Test {
    PairFctory public pairFctory;
    Router public router;
    Me public me;

    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function setUp() public {
        pairFctory = new PairFctory();
        router = new Router(address(pairFctory));
        me = new Me();
    }

    function testDeployPair() public{
        pairFctory.createPair(address(me), USDT);
        

    }
}
