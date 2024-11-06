// SPDX-License-Identifier: MIT

// IStaking.sol

pragma solidity ^0.8.26;

/*///////////////////////////////////////////////////////////////
        STRUCTS
    //////////////////////////////////////////////////////////////*/
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

    error InvalidDuration();
    error NoStakeFound();
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
