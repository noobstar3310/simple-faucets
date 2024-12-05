// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Faucet {
    // State variables
    uint256 public constant DRIP_AMOUNT = 100000000000000000;
    uint256 public constant COOLDOWN_TIME = 48 hours;
    
    // Mapping to track last drip timestamp for each address
    mapping(address => uint256) public lastDripTime;
    
    // Events
    event FundsReceived(address indexed donor, uint256 amount);
    event FundsSent(address indexed recipient, uint256 amount);
    event Deposit(address indexed donor, uint256 amount);
    event WithdrawnByOwner(address indexed owner, uint256 amount);
    
    // Add owner state variable
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    // Add owner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // Modifiers
    modifier canReceiveDrip() {
        require(
            block.timestamp >= lastDripTime[msg.sender] + COOLDOWN_TIME || 
            lastDripTime[msg.sender] == 0,
            "Must wait 48 hours between drips"
        );
        _;
    }
    
    // Allow contract to receive ETH
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
    
    // Function to request funds
    function getFunds() external canReceiveDrip {
        require(address(this).balance >= DRIP_AMOUNT, "Insufficient funds in faucet");
        
        lastDripTime[msg.sender] = block.timestamp;
        
        (bool success, ) = msg.sender.call{value: DRIP_AMOUNT}("");
        require(success, "ETH transfer failed");
        
        emit FundsSent(msg.sender, DRIP_AMOUNT);
    }
    
    // Function to deposit funds into the faucet
    function deposit() external payable {
        require(msg.value > 0, "Must send some ETH");
        emit Deposit(msg.sender, msg.value);
    }
    
    // View functions
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Add withdraw function
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");
        
        emit WithdrawnByOwner(owner, balance);
    }
}
