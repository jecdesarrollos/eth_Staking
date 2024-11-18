
// File: IJERC20.sol



pragma solidity ^0.8.26;

/**
 * @title ERC-20 Token Standard Interface
 */
 
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value); 

    /**
     * @dev Returns the total amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
      * Returns a ~ success boolean value
      * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. 
     * default: 0
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
// File: IStaking.sol



// IStaking.sol

pragma solidity ^0.8.26;

/*///////////////////////////////////////////////////////////////
        STRUCTS
    //////////////////////////////////////////////////////////////*/

/**
     * @dev Represents a single stake by a user.
     * @param amount The amount of tokens staked.
     * @param startTime The timestamp when the stake was initiated.
     * @param duration The duration of the stake in years (1, 2, or 3).
     * @param claimed A flag indicating whether the rewards for this stake have been claimed.
     */

struct Stake {
    uint256 amount; // Amount of tokens staked
    uint256 startTime; // Timestamp of when the stake started
    uint256 duration; // Duration of the stake (1, 2, or 3 years)
    bool claimed; // Flag to track if rewards have been claimed
}

interface IStaking {
    /*///////////////////////////////////////////////////////////////
        EVENTS
    //////////////////////////////////////////////////////////////*/

    event Staked(address indexed user, uint256 amount, uint256 duration);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event OwnerDeposit(address indexed owner, uint256 amount);

    /*///////////////////////////////////////////////////////////////
     //   ERRORS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @dev Thrown when an invalid staking duration is provided.
     * Valid durations are 1, 2, or 3 years.
     */
    error InvalidDuration();

    /**
     * @dev Thrown when there is no Stake.
    */
    error NoStakeFound();

    /**
     * @dev Thrown when the Stake is not mature yet.
    */
    error StakeNotMature();

    /*///////////////////////////////////////////////////////////////
        //VIEWS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Get the staked amount and the address of the staker for a specific user.
     * @param _userAddress The address of the user.
     * @return amount The amount of tokens staked by the user.
     * @return stakerAddress The address of the user who staked the tokens.
     */
    function getStaker(address _userAddress)
        external
        view
        returns (uint256, address);

    /*///////////////////////////////////////////////////////////////
        LOGIC
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Stake a certain amount of tokens for a certain duration
     * @param _amount The amount of tokens to stake
     * @param _duration The duration of the stake in years (1, 2, or 3)
     */

    function stake(uint256 _amount, uint256 _duration)
        external
        returns (uint256, address);

    /**
     * @notice Unstake the tokens
     * @dev If the user unstakes before the duration, they will only get the staked amount
     * If the user unstakes after the duration, they will get the staked amount plus the rewards
     */
    function unStake() external;

    /**
     * @notice Claim the rewards
     * @return reward
     */
    function claimReward() external returns (uint256);

    /**
     * @notice Allows the owner to deposit tokens to ensure liquidity
     * @param _amount The amount of tokens to deposit
     */
    function ownerDeposit(uint256 _amount) external;
}

// File: Staking.sol

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

//import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract Staking is IStaking {
    IERC20 public immutable token; // The ERC20 token used for staking
    address public owner; // Declare the owner variable

    constructor(address _tokenAddress) {
        //address _tokenAddress; // = address(0xd9145CCE52D386f254917e481eB44e9943F39138); // Define the address
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

    // Corrected condition:
    if (block.timestamp >= userStake.startTime + userStake.duration) { 
        // Transfer the total amount (including rewards) only if the stake is mature
        token.transfer(msg.sender, totalAmount); 
    } else {
        // If unstaking early, transfer only the staked amount
        token.transfer(msg.sender, userStake.amount);
    }

    delete stakes[msg.sender];
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
