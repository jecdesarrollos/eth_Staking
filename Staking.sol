// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "./IJERC20.sol";
import "./IStaking.sol";

contract Staking is IStaking {
    IERC20 public immutable token; // The ERC20 token used for staking
    address public owner; // Declare the owner variable

    constructor() {
        address _tokenAddress = address(0xf02A102153DDf132032B7De5D19F43aA049052Dd); // Define the address
        token = IERC20(_tokenAddress); // Assign the address to the token variable
        owner = msg.sender; // the deployer is the owner
    }

    mapping(address => Stake) stakes; // Track stakes for each user

    /**
     * @notice Stake a certain amount of tokens for a certain duration
     * @param _amount The amount of tokens to stake
     * @param _duration The duration of the stake in years (1, 2, or 3)
     */

    function stake(uint256 _amount, uint256 _duration)
        external
        returns (uint256, address)
    {
        uint256 myAmount;
        address myAddress;
        if (_duration < 1 || _duration > 3) {
            revert InvalidDuration();
        }

        token.transferFrom(msg.sender, address(this), _amount);

        stakes[msg.sender] = Stake({
            amount: _amount,
            startTime: block.timestamp,
            duration: _duration * 365 days, // Convert years to seconds
            claimed: false
        });

        emit Staked(msg.sender, _amount, _duration);

        myAmount = _amount;
        myAddress = msg.sender;
        return (myAmount, myAddress);
    }

    /**
     * @notice Allows the owner to deposit tokens to ensure liquidity
     * @param _amount The amount of tokens to deposit
     */
    function ownerDeposit(uint256 _amount) external onlyOwner {
        token.transferFrom(msg.sender, address(this), _amount);
        emit OwnerDeposit(msg.sender, _amount);
    }

    /**
     * @dev Calculates the reward amount for a given user.
     * @param _user The address of the user.
     * @return The calculated reward amount.
     */
    function calculateReward(address _user) internal view returns (uint256) {
        Stake memory userStake = stakes[_user];
        if (block.timestamp < userStake.startTime + userStake.duration) {
            return 0; // No rewards before maturity
        }

        uint256 rewardPercentage = (userStake.duration / 365 days) * 25; // 25% per year
        return (userStake.amount * rewardPercentage) / 100;
    }

    /**
     * @notice Claim the rewards
     * @return reward
     */

    function claimReward() external returns (uint256) {
        Stake storage userStake = stakes[msg.sender];
        if (userStake.amount == 0) {
            revert NoStakeFound();
        }

        uint256 reward = calculateReward(msg.sender);
        if (reward == 0) {
            revert StakeNotMature();
        }

        userStake.claimed = true;
        token.transfer(msg.sender, reward);
        emit RewardsClaimed(msg.sender, reward);
        return reward;
    }

    /**
     * @notice Unstake the tokens
     * @dev If the user unstakes before the duration, they will only get the staked amount
     * If the user unstakes after the duration, they will get the staked amount plus the rewards
     */
    function unStake() external {
        Stake storage userStake = stakes[msg.sender];
        if (userStake.amount == 0) {
            revert NoStakeFound();
        }

        uint256 reward = calculateReward(msg.sender);
        uint256 totalAmount = userStake.amount + reward;

        if (
            block.timestamp < userStake.startTime + userStake.duration &&
            reward > 0
        ) {
            totalAmount = userStake.amount; // Penalize for early unstaking
        }

        delete stakes[msg.sender];
        token.transfer(msg.sender, totalAmount);
        emit Unstaked(msg.sender, totalAmount);
    }

    /**
     * @notice Get the staked amount and the address of the staker for a specific user.
     * @param _userAddress The address of the user.
     * @return amount The amount of tokens staked by the user.
     * @return stakerAddress The address of the user who staked the tokens.
     */
    function getStaker(address _userAddress)
        external
        view
        returns (uint256, address)
    {
        Stake memory staky = stakes[_userAddress];
        return (staky.amount, _userAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}
