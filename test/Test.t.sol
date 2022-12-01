// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PairFactory.sol";

import "../src/Router.sol";

// import "../src/Pair.sol";

import "../src/Metoken.sol";

import "../src/LeToken.sol";


contract Swaptest is Test {
    PairFctory public pairFctory;
    Router public router;
    Me public me;
    Le public le;

    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address USDTholder = 0x68841a1806fF291314946EebD0cdA8b348E73d6D;
    address admin = mkaddr("Admin");
    address user1 = mkaddr("user1");
    address user2 = mkaddr("User2");
    address user3 = mkaddr("User3");
    address alice = vm.addr(1);
    event log(address addr);
    event log2(uint256 bal, string message);

    function setUp() public {
        pairFctory = new PairFctory();
        router = new Router(address(pairFctory));
        me = new Me();
        le = new Le();
    }

    function testDeployPair() public{
        address pair = pairFctory.createPair(address(me), USDT);
        vm.startPrank(USDTholder);
        me.mints(USDTholder,1000e18);
        // le.mints(user1, 1000e18);
        uint balance = IERC2022(USDT).balanceOf(address(USDTholder));
        uint balance2 = me.balanceOf(address(USDTholder));
        emit log2(balance, "USDT holder balance");
        emit log2(balance2, "ME holder balance");
        IERC2022(USDT).approve(address(router), 100e18);
        me.approve(address(router), 100e18);
        router.addliquidity(address(USDT), address(me), 5000000000000000000, 5000000000000000000, USDTholder, 0, 0);
        vm.stopPrank();

    }

    function mkaddr(string memory name) public returns (address) {
        address addr = address(uint160(uint256(keccak256(abi.encodePacked(name)))));
        vm.label(addr, name);
        return addr;
    }
}

interface IERC2022{
    function balanceOf(address addr) external returns(uint256);
    function approve(address spender, uint256 amount) external returns (bool) ;
        function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//113,504,116.066158
