// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PairFactory.sol";

import "../src/Router.sol";

// import "../src/Pair.sol";

import "../src/Metoken.sol";

import "../src/LeToken.sol";

import "../src/LPtoken.sol";


contract Swaptest is Test {
    PairFactory public pairFactory;
    Router public router;
    Me public me;
    Le public le;
    LPtoken  public lptoken;



    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address HEX = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address HEXholder = 0x73f8FC2e74302eb2EfdA125A326655aCF0DC2D1B;
    address USDTholder = 0x68841a1806fF291314946EebD0cdA8b348E73d6D;
    address DAIholder = 0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3;
    address admin = mkaddr("Admin");
    address user1 = mkaddr("user1");
    address user2 = mkaddr("User2");
    address user3 = mkaddr("User3");
    address alice = vm.addr(1);
    event log(address addr);
    event log2(uint256 bal, string message);

    function setUp() public {
        pairFactory = new PairFactory();
        router = new Router(address(pairFactory));
        me = new Me();
        le = new Le();
        // lptoken = new LPtoken();
    }

    function testDeployPairUSDTme() public{
        //address pair = pairFactory.createPair(address(me), address(le));
        vm.label(address(me),"me");
        vm.label(address(router),"router");
        vm.startPrank(USDTholder);
        me._mint(USDTholder,1000e18);
        //le.mints(user1, 1000e18);
        uint balance = IERC2022(USDT).balanceOf(address(USDTholder));
        uint balance2 = me.balanceOf(address(USDTholder));
        emit log2(balance, "USDT holder balance");
        emit log2(balance2, "ME holder balance");
        me.approve(address(router), 100e18);
        IERC2022(USDT).approve(address(router), 100e6);
        router.addliquidity(address(me), address(USDT), 50000000000000000000, 50000000, USDTholder, 0, 0);
       vm.stopPrank();

    }
    function testDeployPairHEXme() public{
        //address pair = pairFactory.createPair(address(me), address(le));
        vm.label(address(me),"me");
        vm.label(address(router),"router");
        vm.startPrank(HEXholder);
        me._mint(HEXholder,1000e18);
        //le.mints(user1, 1000e18);
        uint balance = IERC2022(HEX).balanceOf(address(HEXholder));
        uint balance2 = me.balanceOf(address(HEXholder));
        emit log2(balance, "HEX holder balance");
        emit log2(balance2, "ME holder balance");
        me.approve(address(router), 100e18);
        IERC2022(HEX).approve(address(router), 100e8);
        router.addliquidity(address(me), address(HEX), 50000000000000000000, 5000000000, HEXholder, 0, 0);
       vm.stopPrank();

    }

    function testDeployPairleme() public{
        //address pair = pairFactory.createPair(address(me), address(le));
        vm.label(address(me),"me");
        vm.label(address(le),"le");
        vm.label(address(router),"router");
        vm.startPrank(user1);
        me._mint(user1,1000e18);
        le.mints(user1, 1000e18);
        uint balance = le.balanceOf(address(user1));
        uint balance2 = me.balanceOf(address(user1));
        emit log2(balance, "LE holder balance");
        emit log2(balance2, "ME holder balance");
        me.approve(address(router), 100e18);
        le.approve(address(router), 100e18);
        router.addliquidity(address(me), address(le) ,50000000000000000000, 50000000000000000000, user1, 0, 0);
       vm.stopPrank();

    }

    function testDeployPairDAIWETH() public{
        //address pair = pairFactory.createPair(address(me), address(le));
        vm.label(address(router),"router");
        vm.startPrank(DAIholder);
        uint balance = IERC2022(WETH).balanceOf(address(DAIholder));
        uint balance2 = IERC2022(DAI).balanceOf(address(DAIholder));
        emit log2(balance, "HEX holder balance");
        emit log2(balance2, "ME holder balance");
        IERC2022(WETH).approve(address(router), 100e18);
        IERC2022(DAI).approve(address(router), 100e18);
        router.addliquidity(address(WETH), address(DAI), 50000000000000000000, 50000000000000000000, DAIholder, 0, 0);
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


// forge verify-contract --chain-id 1 --num-of-optimizations 1000000 --watch
//     --compiler-version v0.8.13+commit.fc410830 0xC294b6973A7110197590AB0011295BfD9f75EfeF src/PairFactory.sol:PairFactory Z8P4W843RDB83JD848SWFRI6JVVXGVM9KT