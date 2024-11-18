// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Staking.sol";
//import "../src/IJERC20.sol";

contract MockERC20 is IERC20 {
    
	string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply; // Give initial supply to deployer
    }

    function transfer(address to, uint256 amount) external override returns (bool){
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount; 
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        external
        override
        returns (bool)
    {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        return true;
    }

    // Add a mint function for testing purposes
    function mint(address to, uint256 amount) public {
        totalSupply += amount;
        balanceOf[to] += amount;
    }
}

contract StakingTest is Test {
    Staking public stakingContract;
    MockERC20 public tokenContract;

    function setUp() public {
        tokenContract = new MockERC20("MockToken", "MTK", 18, 10000 ether);
        stakingContract = new Staking(address(tokenContract));
    }

    function testStakingTokens() public {
        // Mint some tokens to the user
        tokenContract.mint(msg.sender, 100 ether);

        // Approve the staking contract to spend tokens
        vm.startPrank(msg.sender); // Use cheat code to act as the user
        tokenContract.approve(address(stakingContract), 100 ether);

        // Stake tokens
        stakingContract.stake(50 ether, 1); // Stake for 1 year

        // Assertions to check if staking was successful
        assertEq(tokenContract.balanceOf(msg.sender), 50 ether);
        vm.stopPrank();
    }

    function testStakingTokens2Years() public {
        // Mint some tokens to the user
        tokenContract.mint(msg.sender, 100 ether);

        // Approve the staking contract to spend tokens
        vm.startPrank(msg.sender); // Use cheat code to act as the user
        tokenContract.approve(address(stakingContract), 100 ether);

        // Stake tokens
        stakingContract.stake(50 ether, 2); // Stake for 2 year

        // Assertions to check if staking was successful
        assertEq(tokenContract.balanceOf(msg.sender), 50 ether);
        vm.stopPrank();
    }

    function testStakingTokens3Years() public {
        // Mint some tokens to the user
        tokenContract.mint(msg.sender, 100 ether);

        // Approve the staking contract to spend tokens
        vm.startPrank(msg.sender); // Use cheat code to act as the user
        tokenContract.approve(address(stakingContract), 100 ether);

        // Stake tokens
        stakingContract.stake(50 ether, 3); // Stake for 3 year

        // Assertions to check if staking was successful
        assertEq(tokenContract.balanceOf(msg.sender), 50 ether);
        vm.stopPrank();
    }

    function testEarlyUnstaking() public {
        // Mint some tokens to the user
        tokenContract.mint(msg.sender, 100 ether);

        // Approve the staking contract to spend tokens
        vm.startPrank(msg.sender);
        tokenContract.approve(address(stakingContract), 100 ether);

        // //Stake tokens for 2 years
        stakingContract.stake(100 ether, 2);

        // Try to unstake early
        stakingContract.unStake();

    // Add a delay to allow the transaction to be mined
    vm.roll(block.number + 1); // Advance the block number by 1

        // //Assertions to check if the user only received their staked amount back
        assertEq(tokenContract.balanceOf(msg.sender), 100 ether);
        vm.stopPrank();
    }

    function testClaimingRewards() public {
        
		// Mint some tokens to the user
        tokenContract.mint(msg.sender, 100 ether);

        // Approve the staking contract
        vm.startPrank(msg.sender);
        tokenContract.approve(address(stakingContract), 100 ether);

        //// Stake tokens for 2 years
        stakingContract.stake(100 ether, 2);

        // Fast-forward time by 2 years
        vm.warp(block.timestamp + (2 * 365 days));

        // Claim rewards
        stakingContract.claimReward();

        // Calculate expected reward (100 * 50% = 50)
        uint256 expectedReward = 50 ether;
		
        // Assertions to check if the user received the correct reward amount
        assertEq(tokenContract.balanceOf(msg.sender), expectedReward);
        vm.stopPrank();
    }

    function testOwnerDeposit() public {
        // Mint tokens to the owner (which is the `this` address in the test)
        tokenContract.mint(address(this), 1000 ether);

        // Approve the staking contract
        vm.startPrank(address(this));
        tokenContract.approve(address(stakingContract), 1000 ether);

        // Deposit tokens as the owner
        stakingContract.ownerDeposit(1000 ether);

        // Assertion to check if the staking contract received the tokens
        assertEq(tokenContract.balanceOf(address(stakingContract)), 1000 ether);
        vm.stopPrank();
    }
}