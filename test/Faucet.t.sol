// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Faucet.sol";

contract FaucetTest is Test {
    Faucet public faucet;
    address public user1;
    address public user2;
    address public owner;
    
    function setUp() public {
        owner = makeAddr("owner");
        vm.startPrank(owner);
        faucet = new Faucet();
        vm.stopPrank();
        
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Fund the faucet
        vm.deal(address(this), 10 ether);
        (bool success,) = address(faucet).call{value: 5 ether}("");
        require(success, "Funding faucet failed");
    }
    
    function testOwnership() public {
        assertEq(faucet.owner(), owner);
    }
    
    function testWithdrawAll() public {
        vm.startPrank(owner);
        uint256 initialBalance = owner.balance;
        uint256 faucetBalance = address(faucet).balance;
        
        faucet.withdrawAll();
        
        assertEq(owner.balance, initialBalance + faucetBalance);
        assertEq(address(faucet).balance, 0);
        vm.stopPrank();
    }
    
    function testWithdrawAllNonOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("Only owner can call this function");
        faucet.withdrawAll();
        vm.stopPrank();
    }
    
    function testWithdrawAllEmpty() public {
        // First withdraw everything as owner
        vm.startPrank(owner);
        faucet.withdrawAll();
        
        // Try to withdraw again
        vm.expectRevert("No funds to withdraw");
        faucet.withdrawAll();
        vm.stopPrank();
    }
    
    function testReceiveFunds() public {
        uint256 initialBalance = address(faucet).balance;
        (bool success,) = address(faucet).call{value: 1 ether}("");
        assertTrue(success);
        assertEq(address(faucet).balance, initialBalance + 1 ether);
    }
    
    function testDeposit() public {
        vm.deal(user1, 2 ether);
        
        vm.startPrank(user1);
        uint256 initialBalance = address(faucet).balance;
        
        // Test deposit function
        faucet.deposit{value: 1 ether}();
        assertEq(address(faucet).balance, initialBalance + 1 ether);
        
        // Test deposit with zero value
        vm.expectRevert("Must send some ETH");
        faucet.deposit{value: 0}();
        
        vm.stopPrank();
    }
    
    function testGetFunds() public {
        vm.startPrank(user1);
        uint256 initialBalance = user1.balance;
        faucet.getFunds();
        assertEq(user1.balance, initialBalance + 0.1 ether);
        vm.stopPrank();
    }
    
    function testCooldownPeriod() public {
        vm.startPrank(user1);
        faucet.getFunds();
        
        vm.expectRevert("Must wait 48 hours between drips");
        faucet.getFunds();
        
        // Fast forward 48 hours
        vm.warp(block.timestamp + 48 hours);
        faucet.getFunds(); // Should work now
        vm.stopPrank();
    }
} 